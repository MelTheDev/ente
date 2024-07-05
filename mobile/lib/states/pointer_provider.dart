import "dart:async";

import "package:flutter/widgets.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/selected_files.dart";

class LastSelectedFileByDragging extends InheritedWidget {
  LastSelectedFileByDragging({
    super.key,
    required super.child,
  });

  final file = ValueNotifier<EnteFile?>(null);

  static LastSelectedFileByDragging? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<LastSelectedFileByDragging>();
  }

  static LastSelectedFileByDragging of(BuildContext context) {
    final LastSelectedFileByDragging? result = maybeOf(context);
    assert(result != null, 'No LastSelectedFileByDragging found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(LastSelectedFileByDragging oldWidget) =>
      file != oldWidget.file;
}

class PointerProvider extends StatefulWidget {
  final Widget child;
  final SelectedFiles selectedFiles;

  ///Check if this should updates on didUpdateWidget. If so, use a state varaible
  ///and update it there on didUpdateWidget.
  final List<EnteFile> files;
  const PointerProvider({
    super.key,
    required this.selectedFiles,
    required this.files,
    required this.child,
  });

  @override
  State<PointerProvider> createState() => _PointerProviderState();
}

class _PointerProviderState extends State<PointerProvider> {
  late Pointer pointer;
  bool _isFingerOnScreenSinceLongPress = false;
  bool _isDragging = false;
  int prevSelectedFileIndex = -1;
  int currentSelectedFileIndex = -1;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    LastSelectedFileByDragging.of(context)
        .file
        .removeListener(swipingToSelectListener);
    LastSelectedFileByDragging.of(context).file.addListener(
          swipingToSelectListener,
        );
  }

  @override
  void dispose() {
    pointer.closeMoveOffsetController();
    pointer.closeUpOffsetStreamController();
    pointer.closeOnTapStreamController();
    pointer.closeOnLongPressStreamController();
    widget.selectedFiles.removeListener(
      swipingToSelectListener,
    );
    super.dispose();
  }

  void swipingToSelectListener() {
    prevSelectedFileIndex = currentSelectedFileIndex;
    final currentSelectedFile =
        LastSelectedFileByDragging.of(context).file.value;
    if (currentSelectedFile == null) {
      print("currentSelectedFile is null");
      return;
    }
    currentSelectedFileIndex = widget.files.indexOf(currentSelectedFile!);
    if (prevSelectedFileIndex != -1 && currentSelectedFileIndex != -1) {
      if ((currentSelectedFileIndex - prevSelectedFileIndex).abs() > 1) {
        late final int startIndex;
        late final int endIndex;
        if (currentSelectedFileIndex > prevSelectedFileIndex) {
          startIndex = prevSelectedFileIndex;
          endIndex = currentSelectedFileIndex;
        } else {
          startIndex = currentSelectedFileIndex;
          endIndex = prevSelectedFileIndex;
        }
        widget.selectedFiles.toggleFilesSelection(
          widget.files
              .sublist(
                startIndex + 1,
                endIndex,
              )
              .toSet(),
        );
      }
    }

    print("currentSelectedFileIndex: $currentSelectedFileIndex "
        "prevSelectedFileIndex: $prevSelectedFileIndex");
  }

  @override
  Widget build(BuildContext context) {
    return Pointer(
      child: Builder(
        builder: (context) {
          pointer = Pointer.of(context);
          return GestureDetector(
            onTap: () {
              pointer.onTapStreamController.add(pointer.pointerPosition);
            },
            onLongPress: () {
              _isFingerOnScreenSinceLongPress = true;
              pointer.onLongPressStreamController.add(pointer.pointerPosition);
            },
            onHorizontalDragUpdate: (details) {
              onDragToSelect(details.localPosition);
            },
            child: Listener(
              onPointerMove: (event) {
                pointer.pointerPosition = event.localPosition;

                //onHorizontalDragUpdate is not called when dragging after
                //long press without lifting finger. This is for handling only
                //this case.
                if (_isFingerOnScreenSinceLongPress &&
                    (event.localDelta.dx.abs() > 0 &&
                        event.localDelta.dy.abs() > 0)) {
                  onDragToSelect(event.localPosition);
                }
              },
              onPointerDown: (event) {
                pointer.pointerPosition = event.localPosition;
              },
              onPointerUp: (event) {
                _isFingerOnScreenSinceLongPress = false;
                _isDragging = false;
                pointer.upOffsetStreamController.add(event.localPosition);

                LastSelectedFileByDragging.of(context).file.value = null;
                currentSelectedFileIndex = -1;
              },
              child: widget.child,
            ),
          );
        },
      ),
    );
  }

  void onDragToSelect(Offset offset) {
    pointer.moveOffsetStreamController.add(offset);
    _isDragging = true;
  }
}

class Pointer extends InheritedWidget {
  Pointer({super.key, required super.child});

  //This is a List<Offset> instead of just and Offset is so that it can be final
  //and still be mutable. Need to have this as final to keep Pointer immutable
  //which is recommended for inherited widgets.
  final _pointerPosition =
      List.generate(1, (_) => Offset.zero, growable: false);

  Offset get pointerPosition => _pointerPosition[0];

  set pointerPosition(Offset offset) {
    _pointerPosition[0] = offset;
  }

  final StreamController<Offset> onTapStreamController =
      StreamController.broadcast();

  final StreamController<Offset> onLongPressStreamController =
      StreamController.broadcast();

  final StreamController<Offset> moveOffsetStreamController =
      StreamController.broadcast();

  final StreamController<Offset> upOffsetStreamController =
      StreamController.broadcast();

  Future<dynamic> closeOnTapStreamController() {
    debugPrint("dragToSelect: Closing onTapStreamController");
    return onTapStreamController.close();
  }

  Future<dynamic> closeOnLongPressStreamController() {
    debugPrint("dragToSelect: Closing onLongPressStreamController");
    return onLongPressStreamController.close();
  }

  Future<dynamic> closeMoveOffsetController() {
    debugPrint("dragToSelect: Closing moveOffsetStreamController");
    return moveOffsetStreamController.close();
  }

  Future<dynamic> closeUpOffsetStreamController() {
    debugPrint("dragToSelect: Closing upOffsetStreamController");
    return upOffsetStreamController.close();
  }

  static Pointer? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<Pointer>();
  }

  static Pointer of(BuildContext context) {
    final Pointer? result = maybeOf(context);
    assert(result != null, 'No Pointer found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(Pointer oldWidget) =>
      moveOffsetStreamController != oldWidget.moveOffsetStreamController ||
      upOffsetStreamController != oldWidget.upOffsetStreamController ||
      onTapStreamController != oldWidget.onTapStreamController ||
      onLongPressStreamController != oldWidget.onLongPressStreamController;
}
