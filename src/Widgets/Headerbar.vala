/*
* Copyright (c) 2011-2016 Felipe Escoto (https://github.com/Philip-Scott/Notes-up)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 59 Temple Place - Suite 330,
* Boston, MA 02111-1307, USA.
*
* Authored by: Felipe Escoto <felescoto95@hotmail.com>
*/

public class ENotes.Headerbar : Gtk.HeaderBar {
    public ENotes.BookmarkButton bookmark_button;

    private Granite.Widgets.ModeButton mode_button;
    private Gtk.MenuButton menu_button;
    private Gtk.Menu menu;
    private Gtk.MenuItem item_new;
    private Gtk.MenuItem item_preff;
    private Gtk.MenuItem item_pdf_export;
    private Gtk.MenuItem item_markdown_export;

    public Gtk.Button search_button;
    public Gtk.SearchEntry search_entry;
    public Gtk.Revealer search_entry_revealer;
    public Gtk.Revealer search_button_revealer;

    public Gtk.GestureSwipe gesture;

    private bool search_visible = false;

    public Headerbar (ENotes.PageInfoEditor page_info) {
        mode_button = new Granite.Widgets.ModeButton ();
        mode_button.append_text (_("View"));
        mode_button.append_text (_("Edit"));
        mode_button.valign = Gtk.Align.CENTER;

        mode_button.set_tooltip_markup (Granite.markup_accel_tooltip (app.get_accels_for_action ("win.change-mode"), _("Change mode")));

        create_menu ();

        var search_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        search_box.halign = Gtk.Align.END;
        search_box.valign = Gtk.Align.CENTER;

        search_entry = new Gtk.SearchEntry();
        search_entry.editable = true;
        search_entry.visibility = true;
        search_entry.expand = true;
        search_entry.max_width_chars = 30;
        search_entry.margin_end = 12;

        search_entry_revealer = new Gtk.Revealer();
        search_entry_revealer.valign = Gtk.Align.CENTER;

        search_button_revealer = new Gtk.Revealer();
        search_entry_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        search_button_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;

        search_button = new Gtk.Button.from_icon_name ("edit-find-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        search_button.set_tooltip_markup (Granite.markup_accel_tooltip (app.get_accels_for_action ("win.find-action"), _("Search your current notebook")));

        search_button.clicked.connect(show_search);

        search_button_revealer.add(search_button);
        search_entry_revealer.add(search_entry);
        search_entry_revealer.reveal_child = false;
        search_button_revealer.reveal_child = true;

        bookmark_button = new BookmarkButton ();

        set_title (null, null);
        set_show_close_button (true);

        pack_start (mode_button);
        pack_end (menu_button);
        pack_end (page_info.get_toggle_button ());
        pack_end (bookmark_button);
        search_box.add (search_button_revealer);
        search_box.add (search_entry_revealer);
        pack_end (search_box);

        this.show_all ();
        connect_signals ();
    }

    private void create_menu () {
        menu = new Gtk.Menu ();
        item_new   = new Gtk.MenuItem.with_label (_("New Notebook"));
        item_preff = new Gtk.MenuItem.with_label (_("Preferences"));

        var item_export = new Gtk.MenuItem.with_label (_("Export as…"));
        var export_submenu = new Gtk.Menu ();

        item_pdf_export = new Gtk.MenuItem.with_label (_("Export as PDF"));
        item_markdown_export = new Gtk.MenuItem.with_label (_("Export as Markdown"));

        export_submenu.add (item_pdf_export);
        export_submenu.add (item_markdown_export);

        item_export.submenu = export_submenu;

        menu.add (item_new);
        menu.add (item_export);
        menu.add (item_preff);

        menu_button = new Gtk.MenuButton ();
        menu_button.set_popup (menu);
        menu_button.set_image (new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR));
        menu.show_all ();
    }

    public void set_mode (ENotes.Mode mode) {
        app.state.mode = mode;
        mode_button.set_active (mode);
    }

    public new void set_title (string? page_title, string? notebook_title) {
        if (page_title != null && notebook_title != null) {
            this.title = page_title + " - " + notebook_title;
        } else if (page_title != null) {
            this.title = page_title + " - ";
        } else if (notebook_title != null) {
            this.title = " - " + notebook_title;
        } else {
            this.title = "";
        }

        this.title = this.title.replace ("&amp;", "&");
    }

    private void connect_signals () {
        item_pdf_export.activate.connect (() => {
            ENotes.FileManager.export_pdf_action ();
        });

        item_markdown_export.activate.connect (() => {
            ENotes.FileManager.export_markdown_action ();
        });

        item_new.activate.connect (() => {
            var dialog = new NotebookDialog ();
            dialog.run ();
        });

        item_preff.activate.connect (() => {
            var dialog = new PreferencesDialog ();
            dialog.run ();
        });

        mode_button.mode_changed.connect ((widget) => {
            if (mode_button.selected == 0) {
                app.state.mode = ENotes.Mode.VIEW;
            } else {
                app.state.mode = ENotes.Mode.EDIT;
            }
        });

        search_entry.activate.connect (() => {
            app.state.search_selected ();
        });

        search_entry.icon_release.connect ((p0, p1) => {
            if (!has_focus) hide_search ();
        });

        search_entry.search_changed.connect(() => {
            app.state.search_field = search_entry.get_text ();
        });

        search_entry.focus_out_event.connect (() => {
            if (search_entry.get_text () == "") {
                hide_search ();
            }

            return false;
        });

        app.state.notify["mode"].connect (() => {
            mode_button.set_active (app.state.mode);
        });

        app.state.update_page_title.connect (() => {
            var notebook = app.state.opened_page_notebook;
            var page = app.state.opened_page;

            set_title (page != null ? page.name : null, notebook != null ? notebook.name : null);
        });

        app.state.page_deleted.connect (() => {
            set_title (null, null);
        });
    }

    public void show_search () {
        search_button_revealer.reveal_child = false;
        search_entry_revealer.reveal_child = true;
        show_all ();
        search_visible = true;
        search_entry.can_focus = true;
        search_entry.grab_focus ();
    }

    public void hide_search () {
        search_entry_revealer.reveal_child = false;
        search_button_revealer.reveal_child = true;
        show_all ();
        search_visible = false;
    }
}
