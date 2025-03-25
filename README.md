## Note Extra Chart Editor
Currently figuring out how Chart Editor works in Codename Engine, so soon this addon will be deprecated.

### Features
- Allows editing the `extra` variable for a Note in the Chart Editor.
![Edit Note Extras Menu](images/readme/NoteExtraMenu.png)

Thats all this adds.

I used it to allow my Custom Note Types to have different effects, when I wanted to.
You could edit the chart manually to add this, but this makes it easier.

## Showcase
![Gif showcasing what it looks like in the chart editor](images/readme/showcase-low.gif)
Checkout the [Example.hx](./songs/Example.hx.disabled) to see how to use it.

## Why it works?
Codename Engine Actually already does most of the work, I just made a friendly UI for it.
inside your Chart, if your note has any data inside of it, it automatically goes into the `extra` variable.

![A json file showing the 4 basic variables for a Note, and an extra value showcasing how the data is stored.](images/readme/chartJson.png)
