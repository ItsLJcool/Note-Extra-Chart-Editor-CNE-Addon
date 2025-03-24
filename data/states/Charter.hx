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

var _prevCharterAutoSaves = false;
var prev_onClosing = WindowUtils.onClosing;
function postCreate() {
    WindowUtils.onClosing = () -> {
        Options.charterAutoSaves = _prevCharterAutoSaves;
        prev_onClosing();
    };
    _prevCharterAutoSaves = Options.charterAutoSaves;
    Options.charterAutoSaves = false;
    replaceTopMenu();

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

//region topMenu replacement util
function __findTopMenuFunction(name:String, idx:Int) {
    var found = topMenu[idx].childs.filter(function(data) {
        if (data == null || data.label == null) return false;
        return data.label == name;
    });
    if (found.length == 0) return () -> {};
    return found.pop().onSelect;
}

function __replaceTopMenuFunction(name:String, idx:Int, newFunc) {
    for (data in topMenu[idx]?.childs) {
        if (data == null || data.label == null || data.label != name) continue;
        data.onSelect = newFunc;
        break;
    }
}
//endregion

//region topMenu replacement

function replaceTopMenu() {
    var new_saveAs = () -> {
        openSubState(new SaveSubstate(Json.stringify(Chart.filterChartForSaving(PlayState.SONG, false), null, Options.editorPrettyPrint ? "\t" : null), {
			defaultSaveFile: Charter.__diff.toLowerCase() + '.json'
		}));
		Charter.undos.save();
    };

    var new_saveTo = function (path:String, ?separateEvents:Bool = false) {
        separateEvents ??= false;
        buildChart();
        addendumSave();
        Chart.save(path, PlayState.SONG, Charter.__diff.toLowerCase(), {saveMetaInChart: false, saveEventsInChart: !separateEvents, prettyPrint: Options.editorPrettyPrint});
    };
    
    // var prevSave = __findTopMenuFunction("Save", 0);
    __replaceTopMenuFunction("Save", 0, () -> {
        #if sys
            new_saveTo(Paths.getAssetsRoot()+'/songs/'+Charter.__song.toLowerCase());
            Charter.undos.save();
            return;
        #end
        new_saveAs();
    });
    __replaceTopMenuFunction("Save As...", 0, new_saveAs);

    __replaceTopMenuFunction("Save Without Events", 0, () -> {
        #if sys
            new_saveTo(Paths.getAssetsRoot()+'/songs/'+Charter.__song.toLowerCase(), true);
            Charter.undos.save();
            return;
		#end
		_file_saveas();
    });
    __replaceTopMenuFunction("Save Without Events As...", 0, () -> {
        openSubState(new SaveSubstate(Json.stringify(Chart.filterChartForSaving(PlayState.SONG, false, false), null, Options.editorPrettyPrint ? "\t" : null), {
			defaultSaveFile: Charter.__diff.toLowerCase() + '.json'
		}));
		Charter.undos.save();
    });

    var new_playtestChart = function(?time:Float = 0, ?opponentMode = false, ?here = false) {
        time ??= 0;
        opponentMode ??= false;
        here ??= false;

        buildChart();
        addendumSave();
		Charter.startHere = here;
		Charter.startTime = Conductor.songPosition;
		PlayState.opponentMode = opponentMode;
		PlayState.chartingMode = true;
		FlxG.switchState(new PlayState());
    }

    // now onto playtesting overriding
    __replaceTopMenuFunction("Playtest", 2, () -> new_playtestChart(0, false));
    __replaceTopMenuFunction("Playtest here", 2, () -> new_playtestChart(Conductor.songPosition, false, true));
    __replaceTopMenuFunction("Playtest as opponent", 2, () -> new_playtestChart(0, true));
    __replaceTopMenuFunction("Playtest as opponent here", 2, () -> new_playtestChart(Conductor.songPosition, true, true));
}

//endregion

var lastClickTime:Float = 0;
var doubleClickDelay:Float = 0.2; // Time in seconds to detect double-click
function update(elapsed:Float) {
    updateCustomAutosave(elapsed);
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

function updateCustomAutosave(elapsed:Float) {
    Charter.autoSaveTimer -= elapsed;

    if (Charter.autoSaveTimer < Options.charterAutoSaveWarningTime && !autoSaveNotif.cancelled && !autoSaveNotif.showedAnimation) {
        if (Options.charterAutoSavesSeperateFolder)
            __autoSaveLocation = Charter.__diff.toLowerCase() + DateTools.format(Date.now(), "%m-%d_%H-%M");
        autoSaveNotif.startAutoSave(Charter.autoSaveTimer, 
            !Options.charterAutoSavesSeperateFolder ? 'Saved chart at '+Charter.__diff.toLowerCase()+'.json!' : 
            'Saved chart at '+__autoSaveLocation+'.json!'
        );
    }
    if (Charter.autoSaveTimer <= 0) {
        Charter.autoSaveTimer = Options.charterAutoSaveTime;
        if (!autoSaveNotif.cancelled) {
            buildChart();
            addendumSave();
            var songPath:String = Paths.getAssetsRoot()+'/songs/'+Charter.__song.toLowerCase();

            if (Options.charterAutoSavesSeperateFolder)
                Chart.save(songPath, PlayState.SONG, __autoSaveLocation, {saveMetaInChart: false, folder: "autosaves", prettyPrint: Options.editorPrettyPrint});
            else
                Chart.save(songPath, PlayState.SONG, Charter.__diff.toLowerCase(), {saveMetaInChart: false, prettyPrint: Options.editorPrettyPrint});
            Charter.undos.save();
        }
        autoSaveNotif.cancelled = false;
    }
}

function checkBoundedChanges(data, idx) {
    var boundedNote = data.boundedNote;
    if (boundedNote.step != data.__note.step) data.__note.step = boundedNote.step;
    if (boundedNote.id != data.__note.id) data.__note.id = boundedNote.id;
    if (boundedNote.type != data.__note.type) data.__note.type = boundedNote.type;
    if (boundedNote.strumLineID != data.__note.strumLineID) data.__note.strumLineID = boundedNote.strumLineID;
    if (boundedNote.susLength != data.__note.susLength) data.__note.susLength = boundedNote.susLength;
}

function addendumSave() {
    trace("addendumSave!");
    var charter_editedNotes_copy = charter_editedNotes.copy();
    for(strumLineID=>strumline in PlayState.SONG.strumLines) {
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
    WindowUtils.onClosing = prev_onClosing;
    Options.charterAutoSaves = _prevCharterAutoSaves;
    charter_editedNotes = [];
}