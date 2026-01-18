# 🤖 Service: Frigate NVR Configuration

## **Overview**
This is the complete configuration for the Frigate NVR service. It is designed to work with **CodeProject.AI** for object, face, and plate detection and utilizes an **NVIDIA RTX A4000** for hardware acceleration.

## **Full Configuration (`config.yml`)**
*Note: This file uses environment variables (e.g., `{MQTT_USER}`) which are defined in the [frigate.env](./frigate.env) file.*

```yaml
# yaml-language-server: $schema=http://{FRIGATE_IP}:5000/api/config/schema.json

mqtt:
  host: {MQTT_BROKER_IP}
  user: {MQTT_USER}
  password: {MQTT_PASSWORD}

detectors:
  # Integrated with CodeProject.AI machine at 172.20.0.6
  codeproject_ai:
    api_url: http://{CPAI_IP}:32168/v1/vision/detection
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
      - "{PLATE_ID_1}"
      - "{PLATE_ID_2}"

audio:
  enabled: True

detect:
  enabled: true # Required for Frigate 0.16+

cameras:
  back_yard:
    ffmpeg:
      inputs:
        - path: rtsp://127.0.0.1:8554/back_yard
          input_args: preset-rtsp-restream
          roles: [audio, detect, record]
    objects:
      track: [person, deer, dog, mouse, cat, face]
    birdseye:
      order: 1

  driveway:
    ffmpeg:
      inputs:
        - path: rtsp://127.0.0.1:8554/driveway
          input_args: preset-rtsp-restream
          roles: [audio, detect, record]
    objects:
      track: [person, deer, dog, car]
    zones:
      near_driveway:
        coordinates: 712,1080,282,1080,193,468,170,292,503,411,982,197,1581,188,1920,147,1920,1080
    review:
      alerts:
        required_zones: near_driveway
    birdseye:
      order: 2

  front_door:
    ffmpeg:
      inputs:
        - path: rtsp://127.0.0.1:8554/front_door
          input_args: preset-rtsp-restream
          roles: [audio, detect, record]
    zones:
      near_front_door:
        coordinates: 361,451,557,473,661,403,1024,366,1024,576,0,576,0,294
    birdseye:
      order: 3

  west_side:
    ffmpeg:
      inputs:
        - path: rtsp://127.0.0.1:8554/west_side
          input_args: preset-rtsp-restream
          roles: [audio, detect, record]
    birdseye:
      order: 4

  garden_north:
    ffmpeg:
      inputs:
        - path: rtsp://127.0.0.1:8554/garden_north
          input_args: preset-rtsp-restream
          roles: [audio, detect, record]
    birdseye:
      order: 5

  garden_south:
    ffmpeg:
      inputs:
        - path: rtsp://127.0.0.1:8554/garden_south
          input_args: preset-rtsp-restream
          roles: [audio, detect, record]
    zones:
      Peppers_and_Kale:
        coordinates: 0.293,0.998,0.292,0.67,0.221,0.635,0.194,0.849,0.082,0.992
      Tomatoes:
        coordinates: 0.392,0.99,0.352,0.712,0.38,0.586,0.42,0.59,0.524,0.996
      Zucchini:
        coordinates: 0.961,0.992,0.697,0.746,0.639,0.611,0.703,0.561,0.998,0.702,0.997,0.994
    birdseye:
      order: 6

  east_side:
    ffmpeg:
      inputs:
        - path: rtsp://127.0.0.1:8554/east_side
          input_args: preset-rtsp-restream
          roles: [audio, detect, record]
    birdseye:
      order: 7

  basement:
    ffmpeg:
      inputs:
        - path: rtsp://127.0.0.1:8554/basement
          input_args: preset-rtsp-restream
          roles: [audio, detect]
    birdseye:
      order: 8

version: 0.16-0