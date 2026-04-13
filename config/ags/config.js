// AGS v3 Configuration for loOS
// GTK4-based status bar with fractional scaling support

const { Hyprland, Battery, Network, WirePlumber, Tray, SystemTray } = await import("resource:///com/github/Aylur/ags/service/system.js");
const { Widget, App, Gtk, Gdk } = await import("resource:///com/github/Aylur/ags/import.js");

// Import services
const hyprland = await Service.import("hyprland");
const battery = await Service.import("battery");
const network = await Service.import("network");
const wireplumber = await Service.import("wireplumber");
const tray = await Service.import("tray");

const { exec, execAsync } = Utils;

// Configuration
const config = {
    bar: {
        layer: "top",
        position: "top",
        height: 30,
        margins: [0, 0, 0, 0],
    }
};

// Utility functions
const range = (length, start = 1) => Array.from({ length }, (_, i) => i + start);

// Workspaces widget
const Workspaces = () => {
    const activeId = hyprland.active.workspace.bind("id");
    const workspaces = hyprland.bind("workspaces").as((ws) => 
        ws.sort((a, b) => a.id - b.id)
    );

    return Widget.Box({
        class_name: "workspaces",
        children: workspaces.as((ws) => 
            range(9).map((id) => {
                const workspace = ws.find((w) => w.id === id);
                return Widget.Button({
                    class_name: activeId.as((i) => 
                        `${i === id ? "active" : ""} ${workspace ? "occupied" : ""}`
                    ),
                    label: [
                        "󰎙", "󰎚", "󰎛", "󰎜", "󰎝",
                        "󰎞", "󰎟", "󰎠", "󰎡"
                    ][id - 1] || "󰎙",
                    on_clicked: () => hyprland.messageAsync(`dispatch workspace ${id}`),
                });
            })
        ),
    });
};

// Window title widget
const WindowTitle = () => {
    const client = hyprland.active.client;
    
    return Widget.Label({
        class_name: "window-title",
        label: client.bind("title").as((t) => {
            if (!t || t === "") return "";
            return t.length > 50 ? t.substring(0, 50) + "..." : t;
        }),
        visible: client.bind("title").as((t) => t && t !== ""),
    });
};

// Clock widget
const Clock = () => {
    const time = Variable("", {
        poll: [1000, "date '+%Y-%m-%d %H:%M'"],
    });

    return Widget.Button({
        class_name: "clock",
        label: time.bind(),
        on_clicked: () => execAsync("gnome-calendar").catch(() => {}),
        tooltip_text: Utils.exec("date '+%A, %B %d, %Y'"),
    });
};

// Audio widget
const Audio = () => {
    const icons = {
        headphones: "󰋋",
        headset: "󰋋",
        handsFree: "󰋋",
        phone: "󰏈",
        portable: "󰏈",
        default: ["󰕿", "󰖀", "󰕾"],
    };

    const getIcon = () => {
        const iconType = wireplumber.icon_name;
        if (wireplumber.muted) return "󰝟";
        
        if (icons[iconType]) return icons[iconType];
        
        const vol = wireplumber.volume;
        const idx = Math.floor(vol * (icons.default.length - 1));
        return icons.default[Math.min(idx, icons.default.length - 1)];
    };

    return Widget.Button({
        class_name: wireplumber.bind("muted").as((m) => `audio ${m ? "muted" : ""}`),
        label: wireplumber.bind("volume").as((v) => {
            const icon = getIcon();
            return `${icon} ${Math.round(v * 100)}%`;
        }),
        on_clicked: () => execAsync("pavucontrol").catch(() => {}),
    });
};

// Network widget
const NetworkWidget = () => {
    const getIcon = () => {
        if (!network.connectivity) return "󰤭";
        if (network.primary === "wired") return "󰈀";
        if (network.wifi) {
            const strength = network.wifi.strength;
            return `󰤨 ${strength}%`;
        }
        return "󰤭";
    };

    const getTooltip = () => {
        if (!network.connectivity) return "Disconnected";
        if (network.primary === "wired") {
            return `Wired: ${network.wired?.ip4 || "No IP"}`;
        }
        if (network.wifi) {
            return `WiFi: ${network.wifi.ssid} (${network.wifi.strength}%)`;
        }
        return "Connected";
    };

    return Widget.Button({
        class_name: network.bind("connectivity").as((c) => `network ${c ? "" : "disconnected"}`),
        label: network.bind("primary").as(() => getIcon()),
        tooltip_text: network.bind("primary").as(() => getTooltip()),
        on_clicked: () => execAsync("nm-connection-editor").catch(() => {}),
    });
};

// Battery widget
const BatteryWidget = () => {
    const getIcon = () => {
        const level = battery.percent;
        const icons = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
        const idx = Math.min(Math.floor(level / 10), icons.length - 1);
        return icons[idx];
    };

    const getClass = () => {
        const level = battery.percent;
        if (battery.charging || battery.charged) return "charging";
        if (level <= 15) return "critical";
        if (level <= 30) return "warning";
        if (level >= 95) return "good";
        return "";
    };

    return Widget.Button({
        class_name: battery.bind("percent").as(() => `battery ${getClass()}`),
        label: battery.bind("percent").as((p) => {
            const icon = getIcon();
            if (battery.charging || battery.charged) {
                return `󰂄 ${p}%`;
            }
            return `${icon} ${p}%`;
        }),
        visible: battery.bind("available"),
        tooltip_text: battery.bind("time-remaining").as((t) => {
            if (!t) return "";
            const hours = Math.floor(t / 3600);
            const minutes = Math.floor((t % 3600) / 60);
            return `${hours}h ${minutes}m remaining`;
        }),
    });
};

// System Tray widget
const SysTray = () => {
    const items = tray.bind("items").as((items) =>
        items.map((item) =>
            Widget.Button({
                class_name: "tray-item",
                child: Widget.Icon({
                    icon: item.bind("icon_name").as((i) => i || ""),
                    pixel_size: 16,
                }),
                tooltip_markup: item.bind("tooltip_markup"),
                on_primary_click: (_, event) => item.activate(event),
                on_secondary_click: (_, event) => item.openMenu(event),
            })
        )
    );

    return Widget.Box({
        class_name: "tray",
        children: items,
        spacing: 10,
    });
};

// Left section
const Left = () =>
    Widget.Box({
        class_name: "left",
        spacing: 8,
        children: [Workspaces(), WindowTitle()],
    });

// Center section
const Center = () =>
    Widget.Box({
        class_name: "center",
        children: [Clock()],
    });

// Right section
const Right = () =>
    Widget.Box({
        class_name: "right",
        hpack: "end",
        spacing: 8,
        children: [Audio(), NetworkWidget(), BatteryWidget(), SysTray()],
    });

// Main bar widget
const Bar = (monitor = 0) =>
    Widget.Window({
        name: `bar-${monitor}`,
        class_name: "bar",
        monitor,
        anchor: ["top", "left", "right"],
        exclusivity: "exclusive",
        layer: "top",
        margins: [0, 0, 0, 0],
        child: Widget.CenterBox({
            start_widget: Left(),
            center_widget: Center(),
            end_widget: Right(),
        }),
    });

// Create bars for all monitors
const monitors = await hyprland.monitors;
const bars = monitors.map((_, i) => Bar(i));

// App configuration
App.config({
    style: App.configDir + "/style.css",
    windows: bars,
    closeWindowDelay: {
        default: 300,
    },
});

export {};
