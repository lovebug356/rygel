/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008 Nokia Corporation.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
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

using GUPnP;
using DBus;
using Gee;

/**
 * Container listing all available tag labels in Tracker DB.
 */
public class Rygel.TrackerTags : Rygel.TrackerMetadataValues {
    /* class-wide constants */
    private const string TITLE = "Tags";
    private const string[] KEY_CHAIN = { "nao:hasTag", "nao:prefLabel", null };

    public TrackerTags (string             id,
                        MediaContainer     parent,
                        TrackerItemFactory item_factory) {
        base (id, parent, TITLE, item_factory, KEY_CHAIN);
    }
}

