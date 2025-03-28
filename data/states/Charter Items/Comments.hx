//a
import funkin.backend.system.Logs;

import flixel.group.FlxTypedSpriteGroup;
import flixel.group.FlxTypedGroup;

import funkin.editors.charter.Charter;
import funkin.editors.ui.UIWindow;
import funkin.editors.ui.UISliceSprite;
import funkin.editors.ui.UISprite;
import funkin.editors.ui.UIState;
import funkin.editors.ui.UITextBox;
import funkin.editors.ui.UIButton;

var comments = [];
var _jsonPath = '/songs/'+Charter.__song.toLowerCase()+"/comments.json";

var commentsGroup = new FlxTypedGroup();
function postCreate() {
    if (Assets.exists(Paths.getPath(_jsonPath))) loadComments();
    else {
        Logs.traceColored([
            Logs.logText("[LJ Charter Addons - Comments] ", 10),
            Logs.logText("No comments found, creating new file", -1),
        ], 0);
        saveComments();
        loadComments();
    }

    topMenu[1].childs.push({
        label: "Create Comment",
        onSelect: () -> {
            var mousePos = FlxG.mouse.getWorldPosition();
            createCommentUI(mousePos.x, mousePos.y / 40);
            var newCommentGroup = commentsGroup.members[commentsGroup.members.length - 1];
            update_moveWindow(newCommentGroup, true, true);
        },
        // keybind: [],
    });
}

var _cameraScroll = {x: 0, y: 0, speed: 400};
function update(elapsed:Float) {

    // if (FlxG.keys.pressed.SHIFT) {
    //     if (controls.LEFT || controls.RIGHT) _cameraScroll.x += ((controls.LEFT ? -1 : 1) * _cameraScroll.speed) * elapsed;
    //     if (controls.UP || controls.DOWN) _cameraScroll.y += ((controls.UP ? -1 : 1) * _cameraScroll.speed) * elapsed;
    // }

    for (group in commentsGroup.members) {
        update_moveWindow(group);
    }
}

function postUpdate(elapsed) {
    // charterCamera.scroll.set(charterCamera.scroll.x + _cameraScroll.x, charterCamera.scroll.y + _cameraScroll.y);
}

//region Window Management

var xLimit = -400;
var _useLimit = true;

var selectedIDX = -1;
function update_moveWindow(group:FlxTypedSpriteGroup, ?forceUpdate:Bool = false, ?centerToMouse:Bool = false) {
    forceUpdate ??= false;
    var mousePos = FlxG.mouse.getWorldPosition();
    var test = group.members.copy();

    var window = test.filter(function(spr:FlxSprite) return spr.ID == 1).pop();
    var titleText = test.filter(function(spr:FlxSprite) return spr.ID == 2).pop(); test = group.members.copy();
    var commentText = test.filter(function(spr:FlxSprite) return spr.ID == 3).pop(); test = group.members.copy();
    var deleteButton = test.filter(function(spr:FlxSprite) return spr.ID == 4).pop();

    if (FlxG.mouse.justPressed && window.hovered) selectedIDX = group.ID;
    else if (FlxG.mouse.justReleased) selectedIDX = -1;

    if (selectedIDX != group.ID && !forceUpdate) return;
    centerToMouse ??= false;
    
    if (centerToMouse) {
        window.setPosition(mousePos.x - (window.bWidth + 15) * 0.5, mousePos.y - (23 + 8) * 0.5);
    } else {
        window.x += FlxG.mouse.deltaX;
        window.y += FlxG.mouse.deltaY;
    }
    if (window.x > xLimit && _useLimit) window.x = xLimit;

    deleteButton.setPosition(window.x +  5, window.y + 5);
    titleText.setPosition(window.x + window.bWidth - titleText.bWidth - 5, window.y + 10);
    commentText.setPosition(window.x + window.bWidth - commentText.bWidth - 5, titleText.y + titleText.bHeight + comment_plusY);
    gridActionType = 0;
}

//endregion

//region Generating Comments
var comment_plusY = 10;
function createCommentUI(xPos:Float, step:Float, ?title:String, ?text:String) {
    text ??= "";
    title ??= "Title";

    if (xPos > xLimit && _useLimit) xPos = xLimit;

    var windowGroup = new FlxTypedSpriteGroup();
    windowGroup.ID = commentsGroup.length;

    var yLevel = (step * 40) + 3;
    
    var windowArea = new UISliceSprite(xPos, yLevel, 350, 300, "editors/ui/context-bg");
    windowArea.ID = 1;
    windowArea.antialiasing = true;
    windowArea.cursor = "hand";
    windowGroup.add(windowArea);

    var commentTitleText = new UITextBox(0, 0, title, windowArea.bWidth - 75, 40, false);
    commentTitleText.ID = 2;
    commentTitleText.antialiasing = true;
    commentTitleText.label.size += 8;
    windowGroup.add(commentTitleText);
    
    var commentText = new UITextBox(0, 0, text, windowArea.bWidth - 10, windowArea.bHeight - 25, true);
    commentText.ID = 3;
    commentText.antialiasing = true;
    commentText.label.size += 8;
    commentText.resize(commentText.bWidth, commentText.bHeight - commentTitleText.bHeight - comment_plusY);
    windowGroup.add(commentText);

    commentsGroup.add(windowGroup);

    var deleteButton = new UIButton(0, 0, "X", function() {
        commentsGroup.remove(windowGroup, true);
        windowGroup.destroy();
    }, 25, 25);
    deleteButton.ID = 4;
    deleteButton.color = 0xFF0000;
    windowGroup.add(deleteButton);

    update_moveWindow(windowGroup, true);
}

function screenCenterUI(uiSprite) { uiSprite.setPosition((FlxG.width - uiSprite.bWidth) * 0.5, (FlxG.height - uiSprite.bHeight) * 0.5); }
function updateUIWindow(uiSprite, ?text:String) {
    text ??= uiSprite.titleSpr.text;
    uiSprite.titleSpr.setPosition(uiSprite.x + 25, uiSprite.y + ((30 - uiSprite.titleSpr.height) * 0.5));
}
//endregion

function saveComments() {
    var updating_comments = [];
    for (group in commentsGroup.members) {
        var test = group.members.copy();
    
        var window = test.filter(function(spr:FlxSprite) return spr.ID == 1).pop();
        var titleText = test.filter(function(spr:FlxSprite) return spr.ID == 2).pop(); test = group.members.copy();
        var commentText = test.filter(function(spr:FlxSprite) return spr.ID == 3).pop();

        var comment = {
            title: titleText.label.text,
            text: commentText.label.text,
            x: window.x,
            step: window.y / 40,
            width: window.bWidth,
            height: window.bHeight,
        };
        updating_comments.push(comment);
    }
    if (updating_comments.length > 1) updating_comments.sort(function(a, b) return a.y - b.y);
    CoolUtil.safeSaveFile(Paths.getAssetsRoot()+_jsonPath, Json.stringify(updating_comments, null, "\t"));
    comments = updating_comments;
}

function loadComments() {
    commentsGroup.destroy();
    
    commentsGroup = new FlxTypedGroup();
    insert(members.indexOf(addEventSpr), commentsGroup);
    commentsGroup.camera = charterCamera;

    var coolio = CoolUtil.parseJson(Paths.getPath(_jsonPath));
    for (data in coolio) createCommentUI(data.x, data.step, data.title, data.text);
    
}

function additionalSave() {
    saveComments();
}