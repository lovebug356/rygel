/*
 * Copyright (C)
 *
 * Author: Thijs Vermeir <thijsvermeir@gmail.com>
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

internal abstract class Rygel.Subtitles {
    const string[] SUBTITLE_EXTENTIONS = {
            "sub",
            "srt",
            "smi",
            "ssa",
            "ass",
            "asc"};

    public static string? get_subtitle_for_uri (string uri) {
        string subtitle_filename = "";
        int ext_start = (int) uri.length - 1;

        if (!uri.has_prefix ("file://"))
          return null;
        subtitle_filename = uri.substring (7);
        while (ext_start > 0 && subtitle_filename[ext_start] != '.' &&
                subtitle_filename[ext_start] != Path.DIR_SEPARATOR)
            ext_start--;
        if (ext_start == 0)
          return null;
        if (subtitle_filename[ext_start] == Path.DIR_SEPARATOR)
          subtitle_filename = subtitle_filename + ".";
        else
          subtitle_filename = subtitle_filename.substring (0, ext_start + 1);

        foreach (var extension in SUBTITLE_EXTENTIONS) {
          string test_filename = subtitle_filename + extension;
          if (FileUtils.test (test_filename, FileTest.EXISTS)) {
            return test_filename;
          }
          test_filename = subtitle_filename + extension.up ();
          if (FileUtils.test (test_filename, FileTest.EXISTS)) {
            return test_filename;
          }
        }
        return null;
    }
}
