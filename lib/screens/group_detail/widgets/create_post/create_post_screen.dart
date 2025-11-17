import 'dart:io';
import 'dart:async';

import 'package:check_bird/screens/group_detail/models/posts_controller.dart';
import 'package:check_bird/screens/group_detail/widgets/create_post/widgets/image_type_dialog.dart';
import 'package:check_bird/services/authentication.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

enum AppState {
  free,
  picked,
  cropped,
}

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key, required this.groupId}) : super(key: key);
  final String groupId;
  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  bool get _hasContent {
    return _image != null || _enteredText.trim().isNotEmpty;
  }

  // change type to File?
  File? _image;
  String _enteredText = "";
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  AppState state = AppState.free;

  Future<void> _pickImage(ImageSource imageSource) async {
    var pickedImg = await ImagePicker().pickImage(source: imageSource);
    if (pickedImg != null) {
      setState(() {
        _image = File(pickedImg.path);
        state = AppState.picked;
      });
    }
  }

  void _clearImage() {
    _image = null;
    setState(() {
      state = AppState.free;
    });
  }

  Future<void> _cropImage() async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: _image!.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 70,
      maxWidth: 700,
      maxHeight: 700,
    );
    if (croppedFile != null) {
      _image = File(croppedFile.path);
      setState(() {
        state = AppState.cropped;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus!.unfocus();
      },
      child: Scaffold(
        // extendBodyBehindAppBar: true,
        // backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Create Post"),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _hasContent
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface,
                    foregroundColor: _hasContent
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.38),
                    elevation: _hasContent ? 1 : 0,
                  ),
                  onPressed: _hasContent
                      ? () {
                          PostsController().createPostInDB(
                              groupId: widget.groupId,
                              text: _enteredText,
                              img: _image);
                          Navigator.pop(context);
                        }
                      : null,
                  child: Text(
                    "Post",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  )),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundImage:
                              NetworkImage(Authentication.user!.photoURL!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Authentication.user!.displayName!,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Authentication.user!.email!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  minLines: 3,
                  decoration: InputDecoration(
                    hintText: "What's on your mind?",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                  onChanged: (value) {
                    setState(() {
                      _enteredText = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(
                      Icons.image_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Add Image",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    if (_image == null)
                      FilledButton.icon(
                        icon: const Icon(Icons.add_photo_alternate_rounded),
                        label: const Text("Add"),
                        onPressed: () async {
                          if (_focusNode.hasPrimaryFocus) {
                            _focusNode.unfocus();
                          }
                          final useCam = await showDialog(
                              context: context,
                              builder: (context) {
                                return const ImageTypeDialog();
                              });
                          if (useCam == null) return;
                          if (useCam) {
                            await _pickImage(ImageSource.camera);
                          } else {
                            await _pickImage(ImageSource.gallery);
                          }
                          await _cropImage();
                        },
                      )
                    else
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            child: const Text("Remove"),
                            onPressed: () {
                              if (_focusNode.hasPrimaryFocus) {
                                _focusNode.unfocus();
                              }
                              _clearImage();
                            },
                          ),
                          FilledButton(
                            child: const Text("Edit"),
                            onPressed: () async {
                              if (_focusNode.hasPrimaryFocus) {
                                _focusNode.unfocus();
                              }
                              await _cropImage();
                            },
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_image != null)
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      maxHeight: 300,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.5),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        _image!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
