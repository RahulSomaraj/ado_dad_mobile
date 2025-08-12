import 'dart:io';
import 'dart:typed_data';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/features/seller/bloc/seller_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class VehicleMoreDetailForm extends StatefulWidget {
  final String advertisementId;
  const VehicleMoreDetailForm({super.key, required this.advertisementId});

  @override
  State<VehicleMoreDetailForm> createState() => _VehicleMoreDetailFormState();
}

class _VehicleMoreDetailFormState extends State<VehicleMoreDetailForm> {
  List<Uint8List?> images = List.generate(10, (index) => null);
  OverlayEntry? _overlayEntry;
  int? selectedIndex;
  bool imageError = false;

  Future<void> _pickImages(ImageSource source, int index) async {
    final picker = ImagePicker();
    if (source == ImageSource.gallery) {
      final pickedFiles =
          await picker.pickMultiImage(); // Select multiple images
      if (pickedFiles.isNotEmpty) {
        setState(() {
          int currentIndex = index; // Start placing images from clicked index
          for (var file in pickedFiles) {
            if (currentIndex < images.length) {
              // images[currentIndex] = File(file.path);
              images[currentIndex] = File(file.path).readAsBytesSync();
              currentIndex++; // Move to the next index
            } else {
              break; // Stop if all slots are filled
            }
          }
        });
        // for (var file in pickedFiles) {
        //   context.read<SellerBloc>().add(SellerEvent.upload(file.path));
        // }
      }
    } else {
      final pickedFile =
          await picker.pickImage(source: source); // Single image from camera
      if (pickedFile != null) {
        setState(() {
          // images[index] =
          //     File(pickedFile.path); // Upload to the clicked box only
          images[index] = File(pickedFile.path).readAsBytesSync();
        });
      }
    }
    _removePopup();
    setState(() {
      imageError = images.every((image) => image == null);
    });
  }

  // Function to show the upload popup near the clicked item
  void _showUploadPopup(BuildContext context, Offset position, int index) {
    _removePopup();

    final screenSize = MediaQuery.of(context).size;
    double popupWidth = 160;
    double popupHeight = 100; // Estimated popup height

    double leftPosition = position.dx;
    double topPosition = position.dy;

    // Adjust if the popup would go off the right edge
    if (leftPosition + popupWidth > screenSize.width) {
      leftPosition = screenSize.width - popupWidth - 10;
    }

    // Adjust if the popup would go off the bottom edge
    if (topPosition + popupHeight > screenSize.height) {
      topPosition = screenSize.height - popupHeight - 10;
    } // Remove existing popup if open

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: leftPosition,
        top: topPosition,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            width: popupWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 5,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _popupOption(Icons.image, "Upload File", () {
                  // _pickImages(index, ImageSource.gallery);
                  _pickImages(ImageSource.gallery, index);
                }),
                Divider(height: 1),
                _popupOption(Icons.camera_alt, "Take a Picture", () {
                  // _pickImage(index, ImageSource.camera);
                  _pickImages(ImageSource.camera, index);
                }),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  // Helper function to create an option in the popup
  Widget _popupOption(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.black54),
            SizedBox(width: 10),
            Text(text, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  // Function to remove the popup
  void _removePopup() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _removeImage(int index) {
    setState(() {
      images[index] = null; // Clear the image
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SellerBloc, SellerState>(
      listener: (context, state) {
        state.maybeWhen(
          successImageUpload: (_) {
            Future.microtask(() {
              context
                  .push('/vehicle-personal-detail/${widget.advertisementId}');
            });
          },
          failure: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error: $error")),
            );
          },
          orElse: () {},
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.whiteColor,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(40.0),
          child: AppBar(
            backgroundColor: AppColors.whiteColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                // context
                //     .read<AddItemBloc>()
                //     .add(const AddItemEvent.navigateEssentialDetail());
              },
            ),
            title: Text(
              'Post your Ad',
              style: AppTextstyle.appbarText,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Form(
            child: Column(
              children: [
                Column(
                  children: [
                    Divider(thickness: 2),
                    // SizedBox(
                    //   height: 50,
                    //   child: Padding(
                    //     padding: const EdgeInsets.symmetric(horizontal: 10),
                    //     child: Center(
                    //       child: Align(
                    //         alignment: Alignment.centerLeft,
                    //         child: Text(
                    //           "More Details",
                    //           style: AppTextstyle.sectionTitleTextStyle,
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // Divider(),
                    Container(
                      width: double.infinity,
                      color: AppColors.whiteColor,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10),
                            Text(
                              'Upload Images(Add Max 10)*',
                              style: AppTextstyle.sectionTitleTextStyle,
                            ),
                            SizedBox(height: 10),
                            image_grid_view(),
                            // SizedBox(height: 10),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                // Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            final selectedImages = images
                                .where((img) => img != null)
                                .cast<Uint8List>()
                                .toList();

                            if (selectedImages.isEmpty) {
                              setState(() {
                                imageError = true;
                              });
                              return;
                            }

                            final bloc = context.read<SellerBloc>();
                            final imageUrls = <String>[];

                            for (final image in selectedImages) {
                              bloc.add(SellerEvent.uploadImageToS3(image));

                              final state = await bloc.stream.firstWhere(
                                (state) => state.maybeWhen(
                                  successImageUpload: (_) => true,
                                  failure: (_) => true,
                                  orElse: () => false,
                                ),
                              );

                              state.maybeWhen(
                                successImageUpload: (url) {
                                  imageUrls.add(url);
                                  print('Url:...................');
                                },
                                failure: (msg) {
                                  print("❌ Upload failed: ");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Upload failed: ")),
                                  );
                                },
                                orElse: () {},
                              );
                            }

                            if (imageUrls.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Please upload at least one image")),
                              );
                              return;
                            }

                            bloc.add(SellerEvent.updateImageUrls(
                              adId: widget.advertisementId,
                              imageUrls: imageUrls,
                            ));
                            // final adId = widget
                            //     .advertisementId; // assuming it's already available
                            // context.push('/vehicle-personal-detail/');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: AppColors.whiteColor,
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "Continue",
                              style: AppTextstyle.buttonText,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 60)
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget image_grid_view() {
    return Container(
      height: 555,
      child: GestureDetector(
        onTap: _removePopup,
        child: GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: 10,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            return GestureDetector(
              onTapUp: (TapUpDetails details) {
                _showUploadPopup(context, details.globalPosition, index);
              },
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                      image: images[index] != null
                          ? DecorationImage(
                              // image: FileImage(images[index]!),
                              image: MemoryImage(images[index]!),

                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: images[index] == null
                        ? Center(
                            child: Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.black54,
                              size: 30,
                            ),
                          )
                        : null,
                  ),
                  // Remove button (appears only if an image is uploaded)
                  if (images[index] != null)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
