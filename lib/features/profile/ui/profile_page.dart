import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/features/profile/bloc/profile_bloc.dart';
import 'package:ado_dad_user/models/profile_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditing = false;

  // final TextEditingController nameController =
  //     TextEditingController(text: "Roman Martinez");
  // final TextEditingController emailController =
  //     TextEditingController(text: "romanmartinez736@gmail.com");
  // final TextEditingController phoneController =
  //     TextEditingController(text: "+91 839 737 1002");

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(const ProfileEvent.fetchProfile());

    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
  }

  void saveProfile() async {
    String? userId = await SharedPrefs().getUserId();
    if (userId == null || userId.isEmpty) {
      print("❌ Error: User ID is missing!");
      return;
    }
    UserProfile updatedProfile = UserProfile(
      id: userId,
      name: nameController.text,
      email: emailController.text,
      phoneNumber: phoneController.text,
      type: "NU",
      profilePic: "default-profile-pic-url",
    );

    context.read<ProfileBloc>().add(ProfileEvent.updateProfile(updatedProfile));

    setState(() {
      isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Light background color
      body: SingleChildScrollView(
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is Loading) {
              return Center(child: CircularProgressIndicator());
            }
            if (state is Loaded || state is Saving) {
              // Update controllers with API data
              if (state is Loaded) {
                nameController.text = state.profile.name;
                emailController.text = state.profile.email;
                phoneController.text = state.profile.phoneNumber;
              }

              return Stack(
                children: [
                  Container(height: 900),
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 50,
                    left: 16,
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.arrow_back, color: Colors.white),
                          iconSize: 28,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Profile",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Profile details card
                  Positioned(
                    top: 120,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                              alignment: Alignment.topRight,
                              child: GestureDetector(
                                onTap: () {
                                  if (isEditing) {
                                    saveProfile();
                                  } else {
                                    setState(() {
                                      isEditing = true;
                                    });
                                  }
                                },
                                child: Image.asset(
                                  isEditing
                                      ? 'assets/images/filter.png'
                                      : 'assets/images/profile-edit-icon.png',
                                ),
                              )),
                          buildLabel("Full Name"),
                          buildTextField(nameController, isEditing),
                          // Divider(),
                          buildLabel("Email"),
                          buildTextField(emailController, isEditing),
                          // Divider(),
                          buildLabel("Phone Number"),
                          buildTextField(phoneController, isEditing),
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    top: 75,
                    left: MediaQuery.of(context).size.width / 2 - 50,
                    child: CircleAvatar(
                      radius: 50,
                      // backgroundImage: AssetImage(
                      //     "assets/profile.jpg"),
                      backgroundColor: AppColors.greyColor,
                    ),
                  ),

                  Positioned(
                    top: 430,
                    left: 20,
                    right: 20,
                    child: Column(
                      children: [
                        buildMenuItem('assets/images/wishlist-profile-icon.png',
                            "Wishlist"),
                        buildMenuItem(
                            'assets/images/add-profile-icon.png', "My Ads"),
                        buildMenuItem(
                            'assets/images/help-profile-icon.png', "Help"),
                        buildMenuItem(
                            'assets/images/logout-profile-icon.png', "Logout",
                            isLogout: true),
                      ],
                    ),
                  ),
                ],
              );
            } else if (state is Error) {
              return Center(child: Text("Error: ${state.message}"));
            }
            return Container();
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: BottomNavBar(),
    );
  }

  Widget buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
    );
  }

  Widget buildTextField(TextEditingController controller, bool isEditable) {
    return TextFormField(
      controller: controller,
      enabled: isEditable,
      style: TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        border: InputBorder.none,
      ),
    );
  }

  Widget buildMenuItem(String image, String title, {bool isLogout = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ListTile(
            leading: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isLogout ? Colors.red[50] : Colors.grey[200],
              ),
              child: Center(
                child: Image.asset(
                  image,
                  color: isLogout ? AppColors.redColor : AppColors.primaryColor,
                ),
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isLogout ? Colors.red : Colors.black,
              ),
            ),
            trailing:
                Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
            onTap: () {
              // Handle menu item actions
            },
          ),
        ),
      ),
    );
  }
}

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: 300,
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(context, 'assets/images/home-icon.png', '/home'),
            _navItem(context, 'assets/images/search-icon.png', '/search'),
            _navItem(context, 'assets/images/seller-icon.png', '/seller'),
            _navItem(context, 'assets/images/chat-icon.png', '/chat'),
            _navItem(context, 'assets/images/profile-icon.png', '/profile'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    String image,
    String? route,
  ) {
    return GestureDetector(
      onTap: () => context.go(route!),
      child: Image.asset(image),
    );
  }
}
