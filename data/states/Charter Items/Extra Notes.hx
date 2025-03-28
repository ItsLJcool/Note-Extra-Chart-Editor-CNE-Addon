//a
import funkin.backend.chart.Chart;
import funkin.editors.charter.Charter;

import funkin.options.Options;

import funkin.editors.ui.UIWindow;
import funkin.editors.ui.UISubstateWindow;

import funkin.editors.SaveSubstate;
import funkin.game.Note;

import funkin.backend.utils.WindowUtils;
import DateTools;
import Date;

static var charter_editedNotes = [];
function postCreate() {
    // please end it all
    for(strumLineID=>strumline in PlayState.SONG.strumLines) {
        var strumNotes = notesGroup.members.filter((data) -> data.strumLineID == strumLineID);
        for (jsonNote in strumline.notes) {
            var worthChecking = false;
            for(field in Reflect.fields(jsonNote)) {
                if (Note.DEFAULT_FIELDS.contains(field)) continue;
                worthChecking = true;
                break;
            }    
            if (!worthChecking) continue;
            for (charterNote in strumNotes) {
                var step = Conductor.getStepForTime(jsonNote.time);
                if (step != charterNote.step) continue;
                if (jsonNote.id != charterNote.id) continue;
                if (jsonNote.type != charterNote.type) continue;
                if (strumLineID != charterNote.strumLineID) continue;
                var extras = Reflect.copy(jsonNote);
                for (remove in Note.DEFAULT_FIELDS) Reflect.deleteField(extras, remove);
                addExtraData(charterNote, extras);
            }
        }
    }
}

function addExtraData(note, extras) {
    var data = {
        boundedNote: note,
        __note: {
            id: note.id,
            type: note.type,
            strumLineID: note.strumLineID,
            step: note.step,
            susLength: note.susLength,
        },
        extras: extras,
    };
    charter_editedNotes.push(data);
    return data;
}

var lastClickTime:Float = 0;
var doubleClickDelay:Float = 0.2; // Time in seconds to detect double-click
function update(elapsed:Float) {
    var currentTime:Float = FlxG.game.ticks / 1000;
    var mousePos = FlxG.mouse.getWorldPosition(charterCamera);

    for (idx=>data in charter_editedNotes) {
        if (Reflect.fields(data.extras).length == 0) {
            charter_editedNotes.remove(data);
            continue;
        }
        if (notesGroup.members.indexOf(data.boundedNote) == -1) {
            var replaced = false;
            for (note in notesGroup.members) {
                var dataNote = data.__note;
                if (note.step != dataNote.step) continue;
                if (note.id != dataNote.id) continue;
                if (note.type != dataNote.type) continue;
                if (note.strumLineID != dataNote.strumLineID) continue;
                data.boundedNote = note;
                replaced = true;
                break;
            }
            if (!replaced) {
                charter_editedNotes.remove(data);
                continue;
            }
        }
        checkBoundedChanges(data, idx);
    }

    for (note in Charter.selection) {
        if (!FlxG.mouse.overlaps(note)) continue;
        if (!FlxG.mouse.justPressed) continue;
        if (!(currentTime - lastClickTime <= doubleClickDelay)) continue;
        editSpecificNote();
        break;
    }

    if (FlxG.mouse.justPressed) lastClickTime = currentTime;
}

function editSpecificNote() {
    openSubState(new UISubstateWindow(true, "UI Windows/CharterEditNoteExtras"));
}

function checkBoundedChanges(data, idx) {
    var boundedNote = data.boundedNote;
    if (boundedNote.step != data.__note.step) data.__note.step = boundedNote.step;
    if (boundedNote.id != data.__note.id) data.__note.id = boundedNote.id;
    if (boundedNote.type != data.__note.type) data.__note.type = boundedNote.type;
    if (boundedNote.strumLineID != data.__note.strumLineID) data.__note.strumLineID = boundedNote.strumLineID;
    if (boundedNote.susLength != data.__note.susLength) data.__note.susLength = boundedNote.susLength;
}

function additionalSave() {
    var charter_editedNotes_copy = charter_editedNotes.copy();
    for (strumLineID=>strumline in PlayState.SONG.strumLines) {
        for (note in strumline.notes) {
            for (i=>data in charter_editedNotes_copy) {
                var dataNote = data.__note;
                var time = Conductor.getTimeForStep(dataNote.step);
                if (note.time != time) continue;
                if (note.id != dataNote.id) continue;
                if (note.type != dataNote.type) continue;
                charter_editedNotes_copy.remove(data);
                for (value in Reflect.fields(note)) {
                    if (Note.DEFAULT_FIELDS.contains(value)) continue;
                    Reflect.deleteField(note, value);
                }
                for (val in Reflect.fields(data.extras)) Reflect.setProperty(note, val, Reflect.field(data.extras, val));
            }
        }
    }
}

function destroy() {
    trace("destroy Extra Notes!");
    charter_editedNotes = [];
}