# Laro Home Assistant Add-ons & HACS integration

[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FDomocn%2FLaro-home-assistant-addon)

Public Home Assistant repository for [Laro](https://laro.food):

1. **HACS custom integration** — sensors, meal calendar, services (cloud or self-host)
2. **Supervisor add-on** — run a full Laro stack inside Home Assistant OS

Repository URL (both): `https://github.com/Domocn/Laro-home-assistant-addon`

## Cloud users (laro.food)

Use the **HACS integration** only. You do **not** need the Supervisor add-on.

### Install via HACS

1. **HACS → Integrations** → ⋮ → **Custom repositories**
2. Repository: `https://github.com/Domocn/Laro-home-assistant-addon`
3. Category: **Integration**
4. Download **Laro** → restart Home Assistant
5. **Settings → Devices & Services → Add Integration → Laro**
6. Server URL: `https://laro.food` + an API token from Laro **Settings → API Tokens**

## Supervisor add-on (self-host inside HA OS)

### [Laro](./laro)

![Supports amd64 Architecture][amd64-shield]
![Supports aarch64 Architecture][aarch64-shield]
![Supports armv7 Architecture][armv7-shield]

Self-hosted family recipe management, meal planning, and cooking assistant **running on your HA box**.

**Features:**
- Recipe management with AI-powered import from any URL
- Weekly meal planning with drag-and-drop calendar
- Auto-generated shopping lists
- UK-first barcode / nutrition helpers
- Step-by-step cooking mode
- Multi-user household support
- Multiple LLM providers (Ollama, OpenAI, Anthropic, Google)

### Installation

1. Click the button above, or manually add this repository to Home Assistant:
   - Go to **Settings → Add-ons → Add-on Store**
   - Click the ⋮ menu → **Repositories**
   - Add: `https://github.com/Domocn/Laro-home-assistant-addon`
2. Find **Laro** in the add-on list
3. Click **Install** → configure → **Start**
4. Access via the Home Assistant sidebar

See the [Laro add-on documentation](./laro/DOCS.md) for configuration options.

## Support

- [Laro public repo](https://github.com/Domocn/Laro)
- [Issue Tracker](https://github.com/Domocn/Laro/issues)

## License

MIT

[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
