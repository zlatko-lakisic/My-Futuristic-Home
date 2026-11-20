#!/usr/bin/env python3
"""Re-announce the Family Car Find Hub tracker to Google.

Google only matches phone sightings of a custom (microcontroller) Find Hub
tracker to the account while it holds that tracker's upcoming EIDs, and one
upload covers about four days. HA runs this daily from
shell_command.car_tracker_findhub_announce (packages/car_tracker.yaml).

It uses a copy of GoogleFindMyTools in /config/tools/googlefindmytools with
its saved Google login (Auth/secrets.json, never in git). The HACS Google
Find My Device integration cannot do this: it only announces from its CLI.

Prints one summary line. Exit 0 when Google accepted the upload.
"""

import os
import sys
import time
import types

TOOL_DIR = os.environ.get("GFMT_DIR", "/config/tools/googlefindmytools")


def _stub_browser_modules() -> None:
    """The auth modules import selenium at load time for the browser login.

    HA has no browser. The login is only needed when secrets.json is missing
    or revoked, so stand in modules that fail with a clear message then.
    """

    def need_login(*_args, **_kwargs):
        raise RuntimeError(
            "Google login needed. Run GoogleFindMyTools main.py on the PC, "
            "then copy Auth/secrets.json to " + TOOL_DIR + "/Auth/"
        )

    try:
        import selenium.webdriver.support.ui  # noqa: F401
        import undetected_chromedriver  # noqa: F401
        return
    except ImportError:
        pass
    names = [
        "selenium",
        "selenium.webdriver",
        "selenium.webdriver.support",
        "selenium.webdriver.support.ui",
        "selenium.webdriver.support.expected_conditions",
        "undetected_chromedriver",
        "chrome_driver",
    ]
    for name in names:
        mod = types.ModuleType(name)
        mod.__getattr__ = lambda _attr: need_login  # type: ignore[method-assign]
        sys.modules[name] = mod
    sys.modules["selenium.webdriver.support.ui"].WebDriverWait = need_login
    sys.modules["chrome_driver"].create_driver = need_login


def main() -> int:
    if not os.path.isfile(os.path.join(TOOL_DIR, "Auth", "secrets.json")):
        print(f"findhub_announce: no Google login at {TOOL_DIR}/Auth/secrets.json")
        return 2
    sys.path.insert(0, TOOL_DIR)
    # Pure-Python packages HA may not ship (h2, hpack, hyperframe, pytz).
    # Appended, so HA's own copies win when present.
    sys.path.append(os.path.join(TOOL_DIR, "_vendor"))
    os.chdir(TOOL_DIR)
    _stub_browser_modules()

    import httpx

    from Auth.spot_token_retrieval import get_spot_token
    from Auth.username_provider import get_username
    from NovaApi.ExecuteAction.LocateTracker.decrypt_locations import (
        is_mcu_tracker,
        retrieve_identity_key,
    )
    from NovaApi.ListDevices.nbe_list_devices import request_device_list
    from ProtoDecoders.decoder import parse_device_list_protobuf
    from ProtoDecoders.DeviceUpdate_pb2 import UploadPrecomputedPublicKeyIdsRequest
    from SpotApi.CreateBleDevice.config import max_truncated_eid_seconds_server
    from SpotApi.CreateBleDevice.util import hours_to_seconds
    from SpotApi.grpc_parser import GrpcParser
    from SpotApi.UploadPrecomputedPublicKeyIds.upload_precomputed_public_key_ids import (
        get_next_eids,
    )

    device_list = parse_device_list_protobuf(request_device_list())
    request = UploadPrecomputedPublicKeyIdsRequest()
    names = []
    start = int(time.time() - hours_to_seconds(3))
    for device in device_list.deviceMetadata:
        reg = device.information.deviceRegistration
        if not is_mcu_tracker(reg):
            continue
        ids = UploadPrecomputedPublicKeyIdsRequest.DevicePublicKeyIds()
        ids.pairDate = reg.pairDate
        ids.canonicId.id = device.identifierInformation.canonicIds.canonicId[0].id
        eik = retrieve_identity_key(reg)
        for info in get_next_eids(
            eik, ids.pairDate, start, duration_seconds=max_truncated_eid_seconds_server
        ):
            ids.clientList.publicKeyIdInfo.append(info)
        request.deviceEids.append(ids)
        names.append(device.userDefinedDeviceName or ids.canonicId.id[:8])

    if not names:
        print("findhub_announce: no custom trackers on the account")
        return 3

    # Same call as spot_request(), but it hides HTTP errors; this one reports.
    url = (
        "https://spot-pa.googleapis.com/google.internal.spot.v1.SpotService/"
        "UploadPrecomputedPublicKeyIds"
    )
    headers = {
        "User-Agent": "com.google.android.gms/244433022 grpc-java-cronet/1.69.0-SNAPSHOT",
        "Content-Type": "application/grpc",
        "Te": "trailers",
        "Authorization": "Bearer " + get_spot_token(get_username()),
        "Grpc-Accept-Encoding": "gzip",
    }
    body = GrpcParser.construct_grpc(request.SerializeToString())
    with httpx.Client(http2=True, timeout=30.0) as client:
        resp = client.post(url, headers=headers, content=body)
    grpc_status = resp.headers.get("grpc-status", "0")
    if resp.status_code != 200 or grpc_status != "0":
        msg = resp.headers.get("grpc-message", "")
        print(
            f"findhub_announce: upload failed http={resp.status_code} "
            f"grpc={grpc_status} {msg}".rstrip()
        )
        return 1
    hours = int(max_truncated_eid_seconds_server // 3600)
    print(f"findhub_announce: ok, {len(names)} tracker(s) ({', '.join(names)}), next {hours} h")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except SystemExit:
        raise
    except Exception as exc:  # one line for the HA log / notification
        print(f"findhub_announce: error {type(exc).__name__}: {exc}")
        sys.exit(1)
