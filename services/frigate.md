# 🤖 Service: Frigate NVR Configuration

## **Overview**
This service handles AI-powered object detection. To maintain security, all sensitive credentials (passwords, RTSP tokens) have been moved to an environment file (`.env`) which is not tracked in version control.

## **Sanitized Configuration (`config.yml`)**

```yaml
# yaml-language-server: $schema=http://{FRIGATE_IP}:5000/api/config/schema.json

mqtt:
  host: {MQTT_BROKER_IP}
  user: {MQTT_USER}
  password: {MQTT_PASSWORD}

detectors:
  deepstack:
    api_url: http://{DEEPSTACK_IP}:32168/v1/vision/detection
    type: deepstack

ffmpeg:
  hwaccel_args: preset-nvidia

go2rtc:
  streams:
    back_yard: rtsp://{CAMERA_USER}:{CAMERA_PASS}@{IP_BACKYARD}/axis-media/media.amp?videocodec=h264&camera=1
    driveway: rtsp://{CAMERA_USER}:{CAMERA_PASS}@{IP_DRIVEWAY}/axis-media/media.amp?videocodec=h264&camera=1
    front_door: rtsp://{IP_FRONT_DOOR}:554/s2
    west_side: rtsp://{CAMERA_USER}:{CAMERA_PASS}@{IP_WEST_SIDE}/axis-media/media.amp?videocodec=h264&camera=1
    basement: rtsp://{IP_BASEMENT}:554/s2
    garden_north: rtsp://{CAMERA_USER}:{CAMERA_PASS}@{IP_GARDEN_N}/axis-media/media.amp?videocodec=h264&camera=1
    garden_south: rtsp://{CAMERA_USER}:{CAMERA_PASS}@{IP_GARDEN_S}/axis-media/media.amp?videocodec=h264&camera=1
    east_side: rtsp://{IP_EAST_SIDE}:554/s2

record:
  enabled: true
  retain:
    days: 20
    mode: motion

snapshots:
  enabled: true
  retain:
    default: 40

birdseye:
  enabled: true
  mode: continuous

face_recognition:
  enabled: true

lpr:
  enabled: True
  known_plates:
    Family Car:
      - {PLATE_ID_1}
      - {PLATE_ID_2}

audio:
  enabled: True

cameras:
  # All cameras utilize internal go2rtc restreams
  back_yard:
    enabled: true
    ffmpeg:
      inputs:
        - path: rtsp://127.0.0.1:8554/back_yard
          input_args: preset-rtsp-restream
          roles: [audio, detect, record]
    objects:
      track: [person, deer, dog, mouse, cat, face]

  driveway:
    enabled: true
    ffmpeg:
      inputs:
        - path: rtsp://127.0.0.1:8554/driveway
          input_args: preset-rtsp-restream
          roles: [audio, detect, record]
    zones:
      near_driveway:
        coordinates: 712,1080,282,1080,193,468,170,292,503,411,982,197,1581,188,1920,147,1920,1080
    review:
      alerts:
        required_zones: near_driveway

  # ... [Other cameras truncated for brevity in documentation]