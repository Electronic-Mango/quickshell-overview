pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var userOptions: ({})

    function read(path, fallback) {
        const parts = path.split(".");
        let current = userOptions;

        for (const part of parts) {
            if (current === null || current === undefined || typeof current !== "object" || !(part in current)) {
                return fallback;
            }
            current = current[part];
        }

        return current === undefined || current === null ? fallback : current;
    }

    function readInt(path, fallback) {
        const value = read(path, fallback);
        const parsed = Number(value);
        return Number.isInteger(parsed) ? parsed : fallback;
    }

    function readReal(path, fallback) {
        const value = read(path, fallback);
        const parsed = Number(value);
        return Number.isFinite(parsed) ? parsed : fallback;
    }

    function readBool(path, fallback) {
        const value = read(path, fallback);
        return typeof value === "boolean" ? value : fallback;
    }

    property QtObject options: QtObject {
        property QtObject appearance: QtObject {
            property bool useMatugenColors: root.readBool("appearance.useMatugenColors", false)
        }

        property QtObject overview: QtObject {
            property int rows: root.readInt("overview.rows", 2)
            property int columns: root.readInt("overview.columns", 5)
            property real scale: root.readReal("overview.scale", 0.16)
            property bool enable: root.readBool("overview.enable", true)
            property bool hideEmptyRows: root.readBool("overview.hideEmptyRows", true)
        }

        property QtObject position: QtObject {
            property int topMargin: root.readInt("position.topMargin", 100)
        }

        property QtObject hacks: QtObject {
            property int arbitraryRaceConditionDelay: root.readInt("hacks.arbitraryRaceConditionDelay", 150)
        }
    }

    Process {
        id: loadUserConfig
        command: [
            "sh",
            "-lc",
            "cfg=\"${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/overview/config.json\"; [ -r \"$cfg\" ] && cat \"$cfg\""
        ]
        stdout: StdioCollector {
            id: configCollector
            onStreamFinished: {
                const payload = configCollector.text.trim();
                if (!payload)
                    return;

                try {
                    const parsed = JSON.parse(payload);
                    if (typeof parsed === "object" && parsed !== null) {
                        root.userOptions = parsed;
                    } else {
                        console.warn("overview: config.json must contain a JSON object; ignoring file");
                    }
                } catch (error) {
                    console.warn("overview: failed to parse user config.json; using defaults", error);
                }
            }
        }
    }

    Component.onCompleted: {
        loadUserConfig.running = true;
    }
}
