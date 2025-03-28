//a
import funkin.backend.utils.WindowUtils;
import funkin.backend.chart.Chart;
import funkin.editors.charter.Charter;
import funkin.options.Options;

import haxe.io.Path;

for (script in Paths.getFolderContent("data/states/Charter Items")) {
    if (Path.extension(script) != "hx") continue;
    script = Path.withoutExtension(script);
    importScript("data/states/Charter Items/"+script);
}
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

}

function update(elapsed:Float) {
    updateCustomAutosave(elapsed);
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

//region topMenu replacement Utils
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

function addendumSave() {
    FlxG.state.stateScripts.call("additionalSave");
}

function destroy() {
    WindowUtils.onClosing = prev_onClosing;
    Options.charterAutoSaves = _prevCharterAutoSaves;
}