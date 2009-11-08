/*
 * Copyright (C) 2008,2009 Nokia Corporation.
 * Copyright (C) 2008,2009 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

using CStuff;

/**
 * Manages the user configuration for Rygel.
 */
public class Rygel.UserConfig : GLib.Object, Configuration {
    protected static const string CONFIG_FILE = "rygel.conf";
    protected static const string IFACE_KEY = "interface";
    protected static const string PORT_KEY = "port";
    protected static const string ENABLED_KEY = "enabled";
    protected static const string TITLE_KEY = "title";
    protected static const string TRANSCODING_KEY = "enable-transcoding";
    protected static const string MP3_TRANSCODER_KEY = "enable-mp3-transcoder";
    protected static const string MP2TS_TRANSCODER_KEY =
                                                    "enable-mp2ts-transcoder";
    protected static const string LPCM_TRANSCODER_KEY =
                                                    "enable-lpcm-transcoder";
    protected static const string LOG_LEVEL_KEY = "log-level";
    protected static const string SUBTITLE_KEY = "enable-subtitles";

    private const string DBUS_SERVICE = "org.freedesktop.DBus";
    private const string DBUS_PATH = "/org/freedesktop/DBus";
    private const string DBUS_INTERFACE = "org.freedesktop.DBus";

    private const string RYGEL_SERVICE = "org.gnome.Rygel1";
    private const string RYGEL_PATH = "/org/gnome/Rygel1";
    private const string RYGEL_INTERFACE = "org.gnome.Rygel1";

    // Our singleton
    private static UserConfig config;

    protected KeyFile key_file;
    private bool read_only;

    private dynamic DBus.Object dbus_obj;
    private dynamic DBus.Object rygel_obj;

    public bool get_upnp_enabled () throws GLib.Error {
        return this.get_bool ("general", ENABLED_KEY);
    }

    public void set_upnp_enabled (bool value) {
        bool enabled = false;

        try {
            enabled = this.get_upnp_enabled ();
        } catch (GLib.Error err) {}

        if (value != enabled) {
            this.enable_upnp (value);
        }
    }

    public string get_interface () throws GLib.Error {
        return this.get_string ("general", IFACE_KEY);
    }

    public void set_interface (string value) {
        this.set_string ("general", IFACE_KEY, value);
    }

    public int get_port () throws GLib.Error {
        return this.get_int ("general", PORT_KEY, uint16.MIN, uint16.MAX);
    }

    public void set_port (int value) {
        this.set_int ("general", PORT_KEY, value);
    }

    public bool get_transcoding () throws GLib.Error {
        return this.get_bool ("general", TRANSCODING_KEY);
    }

    public void set_transcoding (bool value) {
        this.set_bool ("general", TRANSCODING_KEY, value);
    }

    public bool get_mp3_transcoder () throws GLib.Error {
        return this.get_bool ("general", MP3_TRANSCODER_KEY);
    }

    public void set_mp3_transcoder (bool value) {
        this.set_bool ("general", MP3_TRANSCODER_KEY, value);
    }

    public bool get_mp2ts_transcoder () throws GLib.Error {
        return this.get_bool ("general", MP2TS_TRANSCODER_KEY);
    }

    public void set_mp2ts_transcoder (bool value) {
        this.set_bool ("general", MP2TS_TRANSCODER_KEY, value);
    }

    public bool get_lpcm_transcoder () throws GLib.Error {
        return this.get_bool ("general", LPCM_TRANSCODER_KEY);
    }

    public void set_lpcm_transcoder (bool value) {
        this.set_bool ("general", LPCM_TRANSCODER_KEY, value);
    }

    public bool get_enable_subtitles () throws GLib.Error {
      return this.get_bool ("general", SUBTITLE_KEY);
    }

    public void set_enable_subtitles (bool value) {
      this.set_bool ("general", SUBTITLE_KEY, value);
    }

    public LogLevel get_log_level () throws GLib.Error {
        return (LogLevel) this.get_int ("general",
                                        LOG_LEVEL_KEY,
                                        LogLevel.INVALID,
                                        LogLevel.DEBUG);
    }

    public static UserConfig get_default () throws Error {
        if (config == null) {
            config = new UserConfig ();
        }

        return config;
    }

    public UserConfig (bool read_only=true) throws Error {
        this.read_only = read_only;
        this.key_file = new KeyFile ();

        var dirs = new string[2];
        dirs[0] = Environment.get_user_config_dir ();
        dirs[1] = BuildConfig.SYS_CONFIG_DIR;

        string path;
        this.key_file.load_from_dirs (CONFIG_FILE,
                                      dirs,
                                      out path,
                                      KeyFileFlags.KEEP_COMMENTS |
                                      KeyFileFlags.KEEP_TRANSLATIONS);
        debug ("Loaded user configuration from file '%s'", path);

        try {
            DBus.Connection connection = DBus.Bus.get (DBus.BusType.SESSION);

            // Create proxy to Rygel
            this.rygel_obj = connection.get_object (RYGEL_SERVICE,
                                                    RYGEL_PATH,
                                                    RYGEL_INTERFACE);
            // and DBus
            this.dbus_obj = connection.get_object (DBUS_SERVICE,
                                                   DBUS_PATH,
                                                   DBUS_INTERFACE);
        } catch (DBus.Error err) {
            debug ("Failed to connect to session bus: %s", err.message);
        }
    }

    public void save () {
        return_if_fail (!this.read_only);

        // Always write to user's config
        string path = Path.build_filename (Environment.get_user_config_dir (),
                                           CONFIG_FILE);

        size_t length;
        var data = this.key_file.to_data (out length);

        try {
            FileUtils.set_contents (path, data, (long) length);
        } catch (FileError err) {
            critical ("Failed to save configuration data to file '%s': %s",
                      path,
                      err.message);
        }
    }

    public bool get_enabled (string section) throws GLib.Error {
        return this.get_bool (section, ENABLED_KEY);
    }

    public string get_title (string section) throws GLib.Error {
        return this.get_string (section, TITLE_KEY);
    }

    public string get_string (string section,
                              string key) throws GLib.Error {
        var val = this.key_file.get_string (section, key);

        if (val == null || val == "") {
            throw new ConfigurationError.NO_VALUE_SET (
                                        "No value available for '%s'", key);
        }

        return val;
    }

    public Gee.ArrayList<string> get_string_list (string section,
                                                  string key)
                                                  throws GLib.Error {
        var str_list = new Gee.ArrayList<string> ();
        var strings = this.key_file.get_string_list (section, key);

        foreach (var str in strings) {
            str_list.add (str);
        }

        return str_list;
    }

    public int get_int (string section,
                        string key,
                        int    min,
                        int    max)
                        throws GLib.Error {
        int val = this.key_file.get_integer (section, key);

        if (val == 0 || val < min || val > max) {
            throw new ConfigurationError.VALUE_OUT_OF_RANGE (
                                        "Value of '%s' out of range", key);
        }

        return val;
    }

    public Gee.ArrayList<int> get_int_list (string section,
                                            string key)
                                            throws GLib.Error {
        var int_list = new Gee.ArrayList<int> ();
        var ints = this.key_file.get_integer_list (section, key);

        foreach (var num in ints) {
            int_list.add (num);
        }

        return int_list;
    }

    public bool get_bool (string section,
                          string key)
                          throws GLib.Error {
        return this.key_file.get_boolean (section, key);
    }

    public void set_string (string section,
                            string key,
                            string value) {
        this.key_file.set_string (section, key, value);
    }

    public void set_string_list (string                section,
                                 string                key,
                                 Gee.ArrayList<string> str_list) {
        // GConf requires us to provide it GLib.SList
        var strings = new string[str_list.size];
        int i = 0;

        foreach (var str in str_list) {
            if (str != "") {
                strings[i++] = str;
            }
        }

        this.key_file.set_string_list (section, key, strings);
    }

    public void set_int (string section,
                         string key,
                         int    value) {
        this.key_file.set_integer (section, key, value);
    }

    public void set_bool (string section,
                          string key,
                          bool   value) {
        this.key_file.set_boolean (section, key, value);
    }

    private void enable_upnp (bool enable) {
        var dest_path = Path.build_filename (Environment.get_user_config_dir (),
                                             "autostart",
                                             "rygel.desktop");
        var dest = File.new_for_path (dest_path);

        try {
            if (enable) {
                uint32 res;

                // Start service first
                if (this.dbus_obj != null) {
                    this.dbus_obj.StartServiceByName (RYGEL_SERVICE,
                                                      (uint32) 0,
                                                      out res);
                }

                // Then symlink the desktop file to user's autostart dir
                var source_path = Path.build_filename (BuildConfig.DESKTOP_DIR,
                                                       "rygel.desktop");
                try {
                    dest.make_symbolic_link (source_path, null);
                } catch (IOError.EXISTS err) {}

                this.set_bool ("general", ENABLED_KEY, true);
            } else {
                // Stop service first
                if (this.rygel_obj != null) {
                    this.rygel_obj.Shutdown ();
                }

                // Then delete the symlink from user's autostart dir
                try {
                    dest.delete (null);
                } catch (IOError.NOT_FOUND err) {}

                this.set_bool ("general", ENABLED_KEY, false);
            }
        } catch (GLib.Error err) {
            warning ("Failed to %s Rygel service: %s\n",
                     enable? "start": "stop",
                     err.message);
        }
    }
}

