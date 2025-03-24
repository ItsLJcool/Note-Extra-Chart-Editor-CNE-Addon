//a

import flixel.math.FlxPoint;
import Reflect;

import funkin.editors.charter.Charter;

import funkin.editors.ui.UIState;
import funkin.editors.extra.PropertyButton;
import funkin.editors.ui.UIButtonList;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UIText;

import funkin.editors.ui.UISubstateWindow;

winTitle = "Edit Note Extras";

var note = Charter.selection[0];
var data = null;
function postCreate() {
    if (charter_editedNotes == null) return close();

    for (notesData in charter_editedNotes) {
        var dataNote = notesData.__note;
        if (
            dataNote.step != note.step ||
            dataNote.id != note.id ||
            dataNote.type != note.type ||
            dataNote.strumLineID != note.strumLineID
        ) continue;
        data = notesData;
        break;
    }
    if (data == null) data = addExtraData(note);

    noteExtraList = new UIButtonList(0, 0, winWidth - 90, 316, '', FlxPoint.get(winWidth - 100, 55), null, 5);
    noteExtraList.frames = Paths.getFrames('editors/ui/inputbox');
    noteExtraList.cameraSpacing = 0;
    var addNewButton = function(name, prop) {
        var button = new PropertyButton(name, prop, noteExtraList);
        button.propertyText.resize(noteExtraList.buttonSize.x * 0.5 - 20, button.propertyText.bHeight + 20);
        button.propertyText.label.fieldWidth = button.propertyText.bWidth - 10;
        button.valueText.resize(button.valueText.bWidth + 35, button.valueText.bHeight + 20);
        button.resize(noteExtraList.buttonSize.x, noteExtraList.buttonSize.y);
        noteExtraList.add(button);
    }
    noteExtraList.addButton.callback = function() { addNewButton("name", "value"); };

    for (val in Reflect.fields(data.extras)) addNewButton(val, Reflect.field(data.extras, val));

    noteExtraList.x = (winWidth - noteExtraList.bWidth) * 0.5;
    noteExtraList.y = (winHeight - noteExtraList.bHeight) * 0.5;
    add(noteExtraList);
    addLabelOn(noteExtraList, "Custom Values (Advanced)");

    saveButton = new UIButton(0, 0, "Save & Close", function() {
        var prevData = Reflect.copy(data);
        for (val in Reflect.fields(data.extras)) Reflect.deleteField(prevData.extras, val);
        for (vals in noteExtraList.buttons.members) Reflect.setProperty(data.extras, vals.propertyText.label.text, vals.valueText.label.text);
        
        if (noteExtraList.buttons.members.length == 0) charter_editedNotes.remove(data);
        FlxG.state.stateScripts.set("charter_editedNotes", charter_editedNotes);
        close();
    }, 125);
    saveButton.color = 0xFF00FF00;
    saveButton.x = winWidth - saveButton.bWidth - 10;
    saveButton.y = winHeight - saveButton.bHeight - 10;
    add(saveButton);

    closeButton = new UIButton(0, 0, "Close", close, 125);
    closeButton.color = 0xFFFF0000;
    closeButton.x = saveButton.x - closeButton.bWidth - 10;
    closeButton.y = saveButton.y;
    add(closeButton);
}

function addLabelOn(ui:UISprite, text:String) add(new UIText(ui.x, ui.y - 24, 0, text));

function addExtraData(note) {
    var data = {
        boundedNote: note,
        __note: {
            id: note.id,
            type: note.type,
            strumLineID: note.strumLineID,
            step: note.step,
            susLength: note.susLength,
        },
        extras: {},
    };
    charter_editedNotes.push(data);
    return data;
}

function onClose() {
    trace("charter_editedNotes: " + charter_editedNotes.length);
}