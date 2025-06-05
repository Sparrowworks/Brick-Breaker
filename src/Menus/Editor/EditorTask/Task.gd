class_name Task extends Resource

# A script for listing changes to later undo or redo

var before: Dictionary[EditorLevelButton, BrickLevelType]
var after: Dictionary[EditorLevelButton, BrickLevelType]
