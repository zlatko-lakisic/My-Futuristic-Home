export type SystemIcon =
  | 'brain'
  | 'camera'
  | 'cpu'
  | 'droplets'
  | 'radio'
  | 'antenna'
  | 'server'
  | 'zap'
  | 'shield'

export type DeepLink = {
  label: string
  href: string
}

export type Decision = {
  title: string
  body: string
}

export type StackItem = {
  label: string
  value: string
}

export type DiagramStep = {
  label: string
  detail?: string
}

export type RackUnitDetail = {
  u: number
  role: string
  model: string
  detail: string
  anchor?: 'storage' | 'compute'
}

export type System = {
  slug: string
  name: string
  tagline: string
  icon: SystemIcon
  underTheHood: string[]
  metaDescription: string
  whatItDoes: string[]
  howItWorks: string[]
  diagram?: DiagramStep[]
  stack: StackItem[]
  decisions: Decision[]
  goDeeper: DeepLink[]
  /** Backbone-only: full rack model parade */
  rackUnits?: RackUnitDetail[]
}

export const systems: System[] = [
  {
    slug: 'brain',
    name: 'The Brain',
    tagline: 'Orchestrates every automation so the house feels intentional, not noisy.',
    icon: 'brain',
    underTheHood: ['Home Assistant', 'Config as code', 'HACS', 'YAML packages'],
    metaDescription:
      'Home Assistant as the single orchestrator for My Futuristic Home: automations, dashboards, and notifications with config as code.',
    whatItDoes: [
      'Home Assistant is the single orchestrator. Every automation, dashboard, and notification flows through it, so the house feels intentional instead of noisy.',
      'Lights, climate, cameras, irrigation, and watchdogs all report into one place. That is why a dusk watering run and a driveway person alert can share the same notification path without fighting each other.',
      'The brain stays local. Cloud services appear only where a device forces them; the decision layer lives on hardware in the rack.',
    ],
    howItWorks: [
      'A dedicated always-on server runs Home Assistant OS. Configuration lives in Git under homeassistant/: packages, blueprints, scripts, templates, and dashboards.',
      'Changes move through a Git-to-production sync workflow. The live instance pulls reviewed config; secrets stay on the host and never enter the repository.',
      'Automations consume events from MQTT, device integrations, and other subsystems. They do not poll the house into submission. Zigbee, Z-Wave, and Bluetooth radios attach directly so mesh traffic does not depend on a cloud bridge.',
    ],
    diagram: [
      { label: 'Sensors & cameras', detail: 'Events in' },
      { label: 'Home Assistant', detail: 'Decide' },
      { label: 'Actuators & notify', detail: 'Actions out' },
    ],
    stack: [
      { label: 'Orchestrator', value: 'Home Assistant OS' },
      { label: 'Server', value: 'Dedicated SFF PC, Intel Core i7-7700T, 16 GB RAM' },
      { label: 'Radios', value: 'Z-Wave JS + ZHA (SONOFF Zigbee dongle), Bluetooth' },
      { label: 'Config', value: 'YAML packages, blueprints, scripts, templates in Git' },
      { label: 'Database', value: 'MariaDB on the host' },
      { label: 'Integrations', value: 'Z-Wave JS, ZHA, HACS (agentic watering, MSNSwitch), Frigate, MQTT' },
    ],
    decisions: [
      {
        title: 'Config as code.',
        body: 'The house has version control and rollbacks. A bad automation is a git revert away, not a weekend of archaeology.',
      },
      {
        title: 'Secrets stay on the host.',
        body: 'Tokens and passwords never land in Git. The public repo documents structure; the live machine holds credentials.',
      },
      {
        title: 'Automations consume events.',
        body: 'They subscribe to what happened. Polling every device forever is how you invent load and miss the moment.',
      },
    ],
    goDeeper: [
      {
        label: 'homeassistant/README.md',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/blob/main/homeassistant/README.md',
      },
      {
        label: 'Architecture wiki',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Home-Assistant-Architecture',
      },
      {
        label: 'Automations wiki',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Home-Assistant-Automations',
      },
      {
        label: 'Packages wiki',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Home-Assistant-Packages',
      },
      {
        label: 'Dashboards wiki',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Home-Assistant-Dashboards',
      },
    ],
  },
  {
    slug: 'eyes',
    name: 'The Eyes',
    tagline: 'Watches the cameras and only raises events that matter.',
    icon: 'camera',
    underTheHood: ['Frigate', 'TensorRT', 'RTX A4000', 'CodeProject.AI'],
    metaDescription:
      'Local Frigate NVR with TensorRT on an RTX A4000 and CodeProject.AI: camera intelligence that stays inside the house.',
    whatItDoes: [
      'Cameras that understand what they see. The house gets notifications for people, vehicles, and other events that matter, not for every leaf that moves.',
      'Eight cameras cover driveway, garden, and approaches. Detection runs on hardware in the rack; continuous footage never leaves the house for a vendor model.',
      'When something important happens, Frigate publishes an event. Automations decide whether to notify, open a dashboard card, or stay quiet.',
      'The same cameras also serve the perimeter workflow: when a gate opens, Home Assistant pulls a short burst of stills for a people summary. That path lives with The Senses.',
    ],
    howItWorks: [
      'Frigate is the primary detection pipeline, accelerated with TensorRT on an NVIDIA RTX A4000. A dedicated NVR host (i7-8700T) runs the stack in Docker on Ubuntu.',
      'CodeProject.AI sits alongside as a dedicated inference server for object, face, and license plate recognition. Recordings land on high-speed network storage over a direct storage link so 24/7 video does not fight the rest of the network.',
      'Events publish onto the message bus for Home Assistant and other consumers. Detection is a message, not a closed appliance UI. Gate-triggered snapshot bursts are a separate consumer of the same camera feeds; see The Senses for that workflow.',
    ],
    diagram: [
      { label: 'IP cameras', detail: 'Streams' },
      { label: 'Frigate + GPU', detail: 'Detect' },
      { label: 'MQTT events', detail: 'Automate' },
    ],
    stack: [
      { label: 'NVR host', value: 'i7-8700T, 16 GB RAM, Ubuntu 24.04, Docker' },
      { label: 'GPU', value: 'NVIDIA RTX A4000 16 GB, TensorRT' },
      { label: 'Detection', value: 'Frigate (stable-tensorrt)' },
      { label: 'Extra AI', value: 'CodeProject.AI (object, face, LPR)' },
      { label: 'Cameras', value: '8× AXIS and UniFi G3 Flex (standalone)' },
      { label: 'Storage', value: 'Network recordings on NAS2 enterprise SSDs' },
    ],
    decisions: [
      {
        title: 'Inference happens at home.',
        body: 'Footage never leaves the house for a vendor model. Privacy is a placement decision, not a settings toggle.',
      },
      {
        title: 'GPU acceleration is mandatory.',
        body: 'Multi-stream detection has to be real time. Best-effort CPU inference is how you discover events after they matter.',
      },
      {
        title: 'Detection events are messages.',
        body: 'Any automation can react. The NVR is a producer, not a silo that owns every response.',
      },
    ],
    goDeeper: [
      {
        label: 'infrastructure/nvr.md',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/blob/main/infrastructure/nvr.md',
      },
      {
        label: 'services/frigate.md',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/blob/main/services/frigate.md',
      },
      {
        label: 'infrastructure/cameras.md',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/blob/main/infrastructure/cameras.md',
      },
      {
        label: 'NVR & cameras wiki',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Infrastructure-NVR-and-Cameras',
      },
      {
        label: 'The Senses (perimeter + cameras)',
        href: '/My-Futuristic-Home/systems/senses',
      },
    ],
  },
  {
    slug: 'edge-ai',
    name: 'The Edge AI',
    tagline: 'Serves local language models so judgment stays inside the house.',
    icon: 'cpu',
    underTheHood: ['Jetson Orin', 'k3s', 'Ollama', 'Traefik'],
    metaDescription:
      'A Jetson Orin edge cluster running k3s and Ollama: local LLMs for the house with no per-token cloud bill.',
    whatItDoes: [
      'A small AI datacenter in the rack. Language models answer without the internet, so irrigation judgment and other agent work stay inside the house.',
      'Other subsystems call it like any internal service. They do not care that the silicon is a Jetson; they care that the endpoint responds.',
      'When the model is warm and local, there is no per-token bill and no transcript leaving the building.',
    ],
    howItWorks: [
      'A Jetson Orin developer kit runs a single-node k3s Kubernetes cluster. Ollama serves local LLMs with an OpenAI-compatible API.',
      'Traefik handles ingress and TLS for human UIs. Machine consumers, notably the garden watering integration, call the inference endpoint as a normal internal service. Gate people-summaries are a different path: short camera still bursts classified by a cloud vision model today, documented under The Senses.',
      'The full implementation lives in the agentic-orchestration repository: deploy scripts, warm pools, and the coordination layer that keeps the edge platform operable.',
    ],
    diagram: [
      { label: 'k3s on Jetson', detail: 'Cluster' },
      { label: 'Ollama', detail: 'Models' },
      { label: 'House services', detail: 'Consumers' },
    ],
    stack: [
      { label: 'Hardware', value: 'NVIDIA Jetson Orin (~61 GB RAM, 12 cores)' },
      { label: 'OS', value: 'Ubuntu 22.04 (tegra)' },
      { label: 'Orchestration', value: 'k3s single-node' },
      { label: 'Models', value: 'Ollama, OpenAI-compatible /v1 API' },
      { label: 'Ingress', value: 'Traefik (+ Warpgate for operator UI)' },
      { label: 'Repo', value: 'agentic-orchestration' },
    ],
    decisions: [
      {
        title: 'Kubernetes at home is not overkill.',
        body: 'It is the same operational muscle as production: declare what should run, recover when it does not.',
      },
      {
        title: 'Models at the edge mean privacy and zero per-token cost.',
        body: 'Judgment that touches the house should not require a cloud round trip.',
      },
      {
        title: 'The endpoint is a service like any other.',
        body: 'Consumers should not care what hardware is behind it, only that the contract holds.',
      },
    ],
    goDeeper: [
      {
        label: 'jetson_agentic_orchestration.md',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/blob/main/infrastructure/jetson_agentic_orchestration.md',
      },
      {
        label: 'Jetson wiki',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Infrastructure-Jetson-Agentic-Orchestration',
      },
      {
        label: 'agentic-orchestration',
        href: 'https://github.com/zlatko-lakisic/agentic-orchestration',
      },
    ],
  },
  {
    slug: 'garden',
    name: 'The Garden',
    tagline: 'Decides watering at dusk and dawn from weather, soil, and season.',
    icon: 'droplets',
    underTheHood: ['hacs-agentic-watering', 'Orbit BHyve', 'Local LLM'],
    metaDescription:
      'AI dusk and dawn irrigation: an LLM proposes durations, deterministic code validates every number before Orbit BHyve valves open.',
    whatItDoes: [
      'An AI decides how long to water at dusk and dawn based on weather, soil history, and season. Fixed timers waste water; this path aims for judgment with a hard safety rail.',
      'Home Assistant runs the sequence. Orbit BHyve opens the valves. The local LLM proposes minutes per zone; nothing opens until code agrees the numbers are sane.',
      'Every decision is logged so a weird night is reviewable, not mysterious.',
    ],
    howItWorks: [
      'The hacs-agentic-watering custom integration calls the local LLM endpoint with forecast, precip, and zone history. The model reasons and proposes durations (or a skip) per zone.',
      'Deterministic code validates every number before Orbit BHyve valves open. Sequential stations on the same hub get settle delays. A retained MQTT run snapshot lets watering resume after a Home Assistant restart.',
      'Production war story: an LLM once silently converted 60 square meters into roughly 12,600 square feet. That is why numbers are never trusted without validation, and why structured output beats free text.',
    ],
    diagram: [
      { label: 'Weather & soil', detail: 'Context' },
      { label: 'Local LLM', detail: 'Propose' },
      { label: 'Validate → BHyve', detail: 'Actuate' },
    ],
    stack: [
      { label: 'Integration', value: 'hacs-agentic-watering' },
      { label: 'Valves', value: 'Orbit BHyve' },
      { label: 'Inference', value: 'Local LLM on Jetson (OpenAI-compatible)' },
      { label: 'Orchestrator', value: 'Home Assistant blueprints + scripts' },
      { label: 'State', value: 'MQTT retained run snapshot for resume' },
      { label: 'Inputs', value: 'Forecast, precip outlook, soil/valve history' },
    ],
    decisions: [
      {
        title: 'Deterministic code for math, LLM for judgment.',
        body: 'Models are good at weighing messy conditions. They are bad at being an unchecked calculator.',
      },
      {
        title: 'Structured output templates instead of free text.',
        body: 'A schema you can validate beats a paragraph you hope to parse.',
      },
      {
        title: 'Every AI decision is logged and reviewable.',
        body: 'If the garden does something odd at dusk, you should be able to read why.',
      },
    ],
    goDeeper: [
      {
        label: 'garden_agentic_watering.md',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/blob/main/homeassistant/docs_ha/garden_agentic_watering.md',
      },
      {
        label: 'Irrigation wiki',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Home-Assistant-Irrigation-AI-Watering',
      },
      {
        label: 'hacs-agentic-watering',
        href: 'https://github.com/zlatko-lakisic/hacs-agentic-watering',
      },
    ],
  },
  {
    slug: 'nervous-system',
    name: 'The Nervous System',
    tagline: 'Carries events between every subsystem on a board the size of a card.',
    icon: 'radio',
    underTheHood: ['Mosquitto', 'MQTT', 'Pine64'],
    metaDescription:
      'Dedicated Mosquitto MQTT on a Pine64: the boring, reliable message bus that ties the house together.',
    whatItDoes: [
      'Every subsystem talks through one tiny, boring, reliable message bus. Cameras, sensors, automations, and watchdogs share a contract: publish and subscribe.',
      'When the bus is healthy, the house can lose a service and recover without rewriting how everything talks. When the bus dies with a big server, everything feels broken at once.',
      'That is why the nervous system is deliberately small and separate.',
    ],
    howItWorks: [
      'Mosquitto runs on a Pine64 single-board computer with industrial flash and PoE power from the rack midspan. Persistence lives on media chosen for write endurance.',
      'Topics are the contract between producers and consumers. Frigate events, watering run state, and Home Assistant integrations all meet here.',
      'A dedicated low-power board means Home Assistant or Proxmox maintenance does not take the bus down with it. IoT devices reach the broker through a narrow, intentional firewall path, not a flat trust LAN.',
    ],
    diagram: [
      { label: 'Producers', detail: 'Publish' },
      { label: 'Mosquitto', detail: 'Bus' },
      { label: 'Consumers', detail: 'Subscribe' },
    ],
    stack: [
      { label: 'Broker', value: 'Mosquitto 2.x' },
      { label: 'Host', value: 'Pine64 ARM64, Armbian, industrial eMMC' },
      { label: 'Power', value: 'PoE midspan in the rack' },
      { label: 'Protocol', value: 'MQTT publish / subscribe' },
      { label: 'Clients', value: 'Home Assistant, Frigate, IoT integrations, watering state' },
    ],
    decisions: [
      {
        title: 'Loose coupling.',
        body: 'Producers and consumers never need to know about each other. The topic is the API.',
      },
      {
        title: 'The bus outlives any individual service restart.',
        body: 'Put the critical path on hardware that is not also your biggest experiment.',
      },
      {
        title: 'Boring technology in the most critical spot.',
        body: 'MQTT is old, simple, and debuggable at midnight. That is a feature.',
      },
    ],
    goDeeper: [
      {
        label: 'Messaging wiki',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Infrastructure-Messaging',
      },
      {
        label: 'infrastructure/messaging.md',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/blob/main/infrastructure/messaging.md',
      },
    ],
  },
  {
    slug: 'senses',
    name: 'The Senses',
    tagline: 'Six radio languages, one house that hears them all.',
    icon: 'antenna',
    underTheHood: ['Z-Wave', 'Zigbee', 'LoRa', 'NFC'],
    metaDescription:
      'Z-Wave, Zigbee, long range LoRa gate sensors, and NFC entry: the wireless senses Home Assistant listens to as one house.',
    whatItDoes: [
      'The house does not speak one wireless language. Light switches and door contacts talk Z-Wave. Closet lights and presence sensors talk Zigbee. The gates at the edge of the yard talk long range LoRa. And the front door opens with an NFC tap from a phone.',
      'Home Assistant listens to all of it and treats every radio the same way: as one more sense.',
      'When a gate opens, the perimeter announces, the nearest camera confirms with a burst of stills, and an AI summarizes who is approaching. If it looks like a person, a short alert reaches a phone before they reach the door.',
    ],
    howItWorks: [
      'Z-Wave is the wired-feeling mesh. Z-Wave JS runs a Silicon Labs 800 series controller with dozens of in-wall GE and Enbrighten switches and dimmers as mains powered repeaters, Aeotec range extenders between floors, and a few battery door contacts. Every mains switch you add makes the mesh stronger.',
      'Zigbee covers dense lighting and presence. ZHA on a SONOFF Zigbee 3.0 dongle runs IKEA TRADFRI drivers as routers with RODRET remotes bound to them, plus Aqara mmWave presence sensors for closet and basement lights that stay on while you stand still, unlike simple PIR motion.',
      'The LoRa perimeter uses YoLink gate contacts on a proprietary LoRa-family radio through a hub, not a DIY network server. Three gates report open and closed plus battery and signal. On open, Home Assistant grabs a short burst of stills from the paired camera, a cloud vision model classifies PEOPLE or NOPEOPLE, and a one line summary can notify a phone. Frigate person occupancy is the local fallback if vision text is unusable. The cloud call is a pragmatic choice: a handful of stills, not a continuous stream leaving the house.',
      'NFC entry is architecture only. A registered phone tag fires a Home Assistant tag scan, authorization happens in HA, and a lock command goes to Yale locks through the August integration. Operational entry details, tag identities, and unlock conditions are intentionally not published.',
    ],
    diagram: [
      { label: 'Gate opens', detail: 'LoRa contact' },
      { label: 'Snapshot burst', detail: 'Paired camera' },
      { label: 'Vision classify', detail: 'Cloud stills' },
      { label: 'Notify if people', detail: 'Phone summary' },
    ],
    stack: [
      { label: 'Z-Wave', value: 'Z-Wave JS, Silicon Labs 800 series controller' },
      { label: 'Zigbee', value: 'ZHA, SONOFF Zigbee 3.0 USB Dongle Plus V2' },
      { label: 'Lighting mesh', value: 'IKEA TRADFRI drivers, RODRET remotes' },
      { label: 'Presence', value: 'Aqara FP1E mmWave sensors' },
      { label: 'Perimeter', value: 'YoLink LoRa gate contacts via hub' },
      { label: 'Entry', value: 'Yale locks via August, Home Assistant NFC tags' },
    ],
    decisions: [
      {
        title: 'Right radio for the right job.',
        body: 'Z-Wave for in-wall reliability, Zigbee for cheap dense lighting, LoRa for reach beyond WiFi, NFC for intent you can feel.',
      },
      {
        title: 'Mains powered devices double as infrastructure.',
        body: 'Every wall switch strengthens the mesh. Battery endpoints lean on neighbors that never sleep.',
      },
      {
        title: 'The perimeter announces, the cameras confirm, the AI summarizes.',
        body: 'Three independent systems, one notification. Local Frigate can fall back when vision text is junk.',
      },
      {
        title: 'Entry mechanics stay off the internet.',
        body: 'The how-to for opening the doors is the one document this project will never publish.',
      },
    ],
    goDeeper: [
      {
        label: 'zwave_network.md',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/blob/main/homeassistant/docs_ha/zwave_network.md',
      },
      {
        label: 'zigbee_lighting_sensors.md',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/blob/main/homeassistant/docs_ha/zigbee_lighting_sensors.md',
      },
      {
        label: 'lorawan_perimeter.md',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/blob/main/homeassistant/docs_ha/lorawan_perimeter.md',
      },
      {
        label: 'nfc_entry.md',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/blob/main/homeassistant/docs_ha/nfc_entry.md',
      },
      {
        label: 'radio_topology.md',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/blob/main/homeassistant/docs_ha/radio_topology.md',
      },
      {
        label: 'Z-Wave wiki',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Home-Assistant-Z-Wave-Network',
      },
      {
        label: 'Zigbee wiki',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Home-Assistant-Zigbee-Lighting-and-Sensors',
      },
      {
        label: 'NFC entry wiki',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Home-Assistant-NFC-Entry',
      },
    ],
  },
  {
    slug: 'backbone',
    name: 'The Backbone',
    tagline: 'A wall-mount rack that holds routing, switching, WiFi, storage, and compute.',
    icon: 'server',
    underTheHood: ['9U rack', '10G backbone', 'Proxmox', 'UniFi', 'Traefik'],
    metaDescription:
      'The 9U wall-mount rack behind My Futuristic Home: gateway, switching, PoE, storage, compute, and the model parade.',
    whatItDoes: [
      'This is the physical spine. Routing, switching, WiFi control, storage, and compute live in a lockable 9U wall cabinet with active cooling, because infrastructure deserves a home.',
      'Most rack units on the landing page land here. The elevation below is the model parade: what sits in each unit and why.',
      'Around the rack: UniFi WiFi split by role, an mDNS repeater for controlled cross-segment discovery, and Traefik as the edge proxy pattern for services that need tidy ingress.',
    ],
    howItWorks: [
      'Traffic roles are deliberate. Ten gigabit shows up where storage and camera recordings need it; one gigabit is enough everywhere else. A direct storage link between the NVR and NAS2 keeps continuous recording off the shared fabric.',
      'The Beelink EQ14 on the U4 shelf runs control-plane containers: UniFi controller, Traefik with certificate distribution, mDNS repeater, and related helpers. Pine64 MQTT and NAS1 share that shelf.',
      'U1 through U3 pack denser compute and storage: NAS2 for recordings and backups, the Frigate NVR with GPU, and the Home Assistant server. Proxmox covers virtualization strategy and backups where VMs earn their keep.',
    ],
    stack: [
      { label: 'Enclosure', value: 'Tecmojo 9U wall cabinet, active cooling' },
      { label: 'Gateway', value: 'MikroTik hAP ac (RouterOS), 3D-printed rack mount' },
      { label: 'Perimeter switch', value: 'MikroTik CSS326-24G-2S+RM, 10G SFP+' },
      { label: 'Patch', value: 'Rapink 48-port Cat6' },
      { label: 'PoE', value: 'PoE Texas 12-port passive midspan' },
      { label: 'House switch', value: 'TP-Link TL-SG1024' },
      { label: 'Control shelf', value: 'Beelink EQ14, Pine64, NAS1 (CM3588)' },
      { label: 'Dense bay', value: 'NAS2, NVR + RTX A4000, Home Assistant server' },
    ],
    decisions: [
      {
        title: '10G where storage traffic lives, 1G everywhere it does not.',
        body: 'Buy bandwidth for the path that records all night. Do not romanticize it for printers.',
      },
      {
        title: 'Wall-mount rack with active cooling.',
        body: 'Infrastructure deserves a home you can lock, label, and hear the fans on when something is wrong.',
      },
      {
        title: 'Everything patched and labeled.',
        body: 'Failures should be diagnosable at 11pm without guessing which cable is which.',
      },
    ],
    goDeeper: [
      {
        label: 'infrastructure/hardware.md',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/blob/main/infrastructure/hardware.md',
      },
      {
        label: 'infrastructure/networking.md',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/blob/main/infrastructure/networking.md',
      },
      {
        label: 'infrastructure/switching.md',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/blob/main/infrastructure/switching.md',
      },
      {
        label: 'infrastructure/proxmox.md',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/blob/main/infrastructure/proxmox.md',
      },
      {
        label: 'Hardware wiki',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Infrastructure-Hardware',
      },
      {
        label: 'Proxmox wiki',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Infrastructure-Proxmox',
      },
    ],
    rackUnits: [
      {
        u: 9,
        role: 'Gateway',
        model: 'MikroTik hAP ac',
        detail:
          'Primary gateway on RouterOS. Custom 3D-printed rack mount holds it cleanly in the bay beside active cooling.',
      },
      {
        u: 8,
        role: 'Switching',
        model: 'MikroTik CSS326-24G-2S+RM',
        detail: 'Perimeter switch with 10G SFP+ backbone ports reserved for storage and uplink paths.',
      },
      {
        u: 7,
        role: 'Patch Panel',
        model: 'Rapink 48-port Cat6',
        detail: 'House-wide copper termination, labeled so midnight fault finding stays sane.',
      },
      {
        u: 6,
        role: 'PoE',
        model: 'PoE Texas 12-port midspan',
        detail: 'Passive midspan feeding access points and IoT endpoints with power and data.',
      },
      {
        u: 5,
        role: 'Controllers',
        model: 'TP-Link TL-SG1024',
        detail: 'House LAN switching for trusted wired devices and AP uplinks.',
      },
      {
        u: 4,
        role: 'Storage / control shelf',
        model: 'Beelink EQ14 · Pine64 · NAS1',
        detail:
          'UniFi controller, Traefik, and mDNS repeater on the EQ14; MQTT on Pine64; NAS1 on a FriendlyElec CM3588 with NVMe RAID.',
        anchor: 'storage',
      },
      {
        u: 3,
        role: 'Storage',
        model: 'NAS2',
        detail:
          'High-speed recordings and backups: enterprise SSDs, multi-NIC, direct link toward the NVR for continuous video.',
        anchor: 'storage',
      },
      {
        u: 2,
        role: 'Compute',
        model: 'NVR + virtualization',
        detail:
          'Frigate NVR with RTX A4000, plus Proxmox hosts for VMs and LXCs that earn a place on virtualization.',
        anchor: 'compute',
      },
      {
        u: 1,
        role: 'Home Assistant Server',
        model: 'SFF i7-7700T',
        detail: 'Always-on automation brain. Dedicated hardware so the orchestrator is not a guest on someone else\'s experiment.',
      },
    ],
  },
  {
    slug: 'safety-net',
    name: 'The Safety Net',
    tagline: 'Power-cycles devices that stop responding so the house can heal itself.',
    icon: 'zap',
    underTheHood: ['MSNSwitch', 'hacs-msnswitch', 'Watchdogs'],
    metaDescription:
      'MSNSwitch watchdogs and hacs-msnswitch: self-healing power cycles when critical devices freeze.',
    whatItDoes: [
      'The house notices when a device freezes and fixes it before anyone else has to. Gateways, NVR, storage, and edge AI sit on smart outlets that can pull the plug with intent.',
      'Self-healing beats human paging for the boring failures: a hung box that just needs power. Escalation and cooldowns keep a flapping device from getting hammered.',
      'Every automated recovery leaves a trace so you can see what the safety net did overnight.',
    ],
    howItWorks: [
      'MSNSwitch smart outlets watch device health with independent ping logic. After consecutive failures, they hard power-cycle the outlet.',
      'The hacs-msnswitch integration exposes outlets to Home Assistant for visibility and control, while the watchdog loop itself does not depend on Home Assistant being healthy.',
      'Targets are chosen by role: edge routing, NVR, NAS and MQTT, basement storage and Jetson. Cooldowns and escalation stop a bad loop from becoming a worse one.',
    ],
    diagram: [
      { label: 'Health check', detail: 'Ping' },
      { label: 'MSNSwitch', detail: 'Decide' },
      { label: 'Power cycle', detail: 'Recover' },
    ],
    stack: [
      { label: 'Outlets', value: 'MSN Switch 2 with independent health checks' },
      { label: 'Integration', value: 'hacs-msnswitch' },
      { label: 'Orchestration', value: 'Home Assistant visibility + automations' },
      { label: 'Policy', value: 'Consecutive failures, cooldowns, escalation' },
    ],
    decisions: [
      {
        title: 'Self-healing before human paging.',
        body: 'A frozen NVR at 3am should not require a person with a flashlight as the first responder.',
      },
      {
        title: 'Watchdogs are independent of the thing they watch.',
        body: 'If Home Assistant is down, the outlet can still cycle the box that matters.',
      },
      {
        title: 'Every automated recovery leaves a trace.',
        body: 'Silent healing is how you lose trust. Logged healing is how you sleep.',
      },
    ],
    goDeeper: [
      {
        label: 'infrastructure/msn_switches.md',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/blob/main/infrastructure/msn_switches.md',
      },
      {
        label: 'hacs-msnswitch',
        href: 'https://github.com/zlatko-lakisic/hacs-msnswitch',
      },
    ],
  },
  {
    slug: 'moat',
    name: 'The Moat',
    tagline: 'Keeps cheap IoT gadgets far away from the servers that matter.',
    icon: 'shield',
    underTheHood: ['RouterOS', 'VLANs', 'Segmented WiFi', 'mDNS repeater'],
    metaDescription:
      'Four networks by role: perimeter, house LAN, trusted WiFi, and isolated IoT, with a controlled mDNS bridge.',
    whatItDoes: [
      'Four networks by role, so a compromised gadget hits a wall instead of a server. Cheap IoT is assumed hostile until proven otherwise.',
      'Trusted wired devices, personal WiFi, isolated IoT WiFi, and a perimeter for management and storage each get their own place to stand.',
      'Convenience still exists, but only through explicit narrow bridges, never through flattening the moat.',
    ],
    howItWorks: [
      'RouterOS firewall policy separates a perimeter segment (management, storage, surveillance control), a house LAN for trusted wired devices, trusted WiFi for people, and an isolated IoT WiFi for gadgets.',
      'Default deny between segments. What may talk to what is intentional: IoT reaches the MQTT broker on a narrow path; cameras ingest on a path that does not grant them the management plane; storage traffic can bypass the shared switch when volume demands it.',
      'The mDNS repeater is one deliberate exception. Discovery for Cast, printers, and similar protocols can cross segments without opening full LAN trust. UniFi SSIDs map to roles; Traefik sits at the edge for services that need tidy HTTPS ingress.',
      'Other narrow bridges are cloud by design and kept small: a YoLink hub for long range gate contacts, August for Yale locks, and short vision calls that classify a burst of gate stills. They are guests with a job, not a flattened trust model.',
    ],
    diagram: [
      { label: 'IoT WiFi', detail: 'Untrusted' },
      { label: 'Firewall', detail: 'Default deny' },
      { label: 'Perimeter', detail: 'Servers' },
    ],
    stack: [
      { label: 'Firewall', value: 'MikroTik RouterOS' },
      { label: 'Segmentation', value: 'VLANs by role' },
      { label: 'WiFi', value: 'UniFi APs, SSIDs mapped to roles' },
      { label: 'Discovery bridge', value: 'mDNS repeater (narrow, intentional)' },
      { label: 'Edge proxy', value: 'Traefik ingress pattern' },
    ],
    decisions: [
      {
        title: 'Default deny between segments.',
        body: 'Allow lists are how you sleep. Flat LANs are how a lightbulb becomes a pivot.',
      },
      {
        title: 'IoT devices are assumed hostile.',
        body: 'They earn reach one port at a time, not by sitting on the same broadcast domain as the NAS.',
      },
      {
        title: 'Convenience features get explicit narrow bridges.',
        body: 'mDNS repeat and MQTT allow-lists are deliberate. Broad trust is not.',
      },
    ],
    goDeeper: [
      {
        label: 'infrastructure/networking.md',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/blob/main/infrastructure/networking.md',
      },
      {
        label: 'Networking wiki',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Infrastructure-Networking',
      },
      {
        label: 'services/mdns_repeater.md',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/blob/main/services/mdns_repeater.md',
      },
      {
        label: 'mDNS wiki',
        href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Services-mDNS-Repeater',
      },
    ],
  },
]

export function getSystem(slug: string): System | undefined {
  return systems.find((s) => s.slug === slug)
}

export function getNextSystem(slug: string): System {
  const i = systems.findIndex((s) => s.slug === slug)
  return systems[(i + 1) % systems.length]!
}

export const systemBySlug = Object.fromEntries(systems.map((s) => [s.slug, s])) as Record<
  string,
  System
>
