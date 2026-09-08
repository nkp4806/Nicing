import GLib from 'gi://GLib';
import Gio from 'gi://Gio';
import St from 'gi://St';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

export default class NeetMetricsExtension extends Extension {
    enable() {
        this._label = new St.Label({
            text: 'CPU --   RAM --   GPU --',
            y_align: 2,
            style_class: 'neet-metrics',
        });

        Main.panel._rightBox.insert_child_at_index(this._label, 0);

        this._cancellable = new Gio.Cancellable();

        this._update();

        this._timeout = GLib.timeout_add_seconds(
            GLib.PRIORITY_DEFAULT,
            2,
            () => {
                this._update();
                return GLib.SOURCE_CONTINUE;
            }
        );
    }

    disable() {
        if (this._timeout) {
            GLib.Source.remove(this._timeout);
            this._timeout = null;
        }

        this._cancellable?.cancel();
        this._cancellable = null;

        this._label?.destroy();
        this._label = null;
    }

    _update() {
        if (!this._label || this._cancellable?.is_cancelled())
            return;

        try {
            const proc = Gio.Subprocess.new(
                [GLib.get_home_dir() + '/.local/bin/neet-metrics.sh'],
                Gio.SubprocessFlags.STDOUT_PIPE
            );

            proc.communicate_utf8_async(
                null,
                this._cancellable,
                (process, result) => {
                    try {
                        const [, stdout] = process.communicate_utf8_finish(result);

                        if (stdout?.trim() && this._label)
                            this._label.text = stdout.trim();
                    } catch (e) {
                        if (!this._cancellable?.is_cancelled() && this._label)
                            this._label.text = 'CPU --   RAM --   GPU --';
                    }
                }
            );
        } catch (e) {
            if (this._label)
                this._label.text = 'CPU --   RAM --   GPU --';
        }
    }
}
