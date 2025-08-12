import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/features/home/bloc/advertisement_bloc.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CategoryListPage extends StatefulWidget {
  final String categoryId;
  final String categoryTitle;
  const CategoryListPage(
      {super.key, required this.categoryId, required this.categoryTitle});

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  late final List<AddModel> filteredAds;
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  List<AddModel> _categoryAds = [];
  final ScrollController _scrollController = ScrollController();
  Map<String, dynamic> _filters = {};

  @override
  void initState() {
    super.initState();
    _fetchCategoryAds(); // First load

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        if (!_isLoading && _hasMore) {
          _fetchCategoryAds();
        }
      }
    });
  }

  Future<void> _fetchCategoryAds() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<AdvertisementBloc>().repository;
      final result = await repo.fetchAllAds(
        page: _page,
        categoryId: widget.categoryId,
        minYear: _filters['minYear'] as int?, // <-- NEW
        maxYear: _filters['maxYear'] as int?, // <-- NEW
        brands: (_filters['brands'] as List?)?.cast<String>(),
      );

      setState(() {
        _page += 1;
        _hasMore = result.hasNext;
        _categoryAds.addAll(result.data);
      });
    } catch (e) {
      print("❌ Error fetching category ads: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       backgroundColor: AppColors.whiteColor,
  //       leading: IconButton(
  //           onPressed: () {
  //             context.go('/home');
  //           },
  //           icon: Icon(Icons.arrow_back)),
  //       title: Text(widget.categoryTitle, style: AppTextstyle.appbarText),
  //     ),
  //     body: BlocBuilder<AdvertisementBloc, AdvertisementState>(
  //       builder: (context, state) {
  //         if (state is ListingsLoaded) {
  //           // final filteredAds = state.listings
  //           //     .where((ad) => ad.category == widget.categoryId)
  //           //     .toList();
  //           final filteredAds = state.listings
  //               .where((ad) =>
  //                   ad.category.trim().toLowerCase() ==
  //                   widget.categoryId.trim().toLowerCase())
  //               .toList();

  //           return ListView.builder(
  //             itemCount: filteredAds.length,
  //             itemBuilder: (context, index) {
  //               final ad = filteredAds[index];
  //               print("category: ${ad.category} &  ${ad.id}");
  //               print('🔎 Filtering for categoryId: "${widget.categoryId}"');

  //               return Padding(
  //                 padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  //                 child: Card(
  //                   color: AppColors.whiteColor,
  //                   elevation: 5,
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(15),
  //                   ),
  //                   child: ListTile(
  //                     leading: ClipRRect(
  //                       borderRadius: BorderRadius.circular(8),
  //                       child: ad.images.isNotEmpty
  //                           ? Image.network(ad.images[0],
  //                               width: 60, height: 60, fit: BoxFit.cover)
  //                           : const SizedBox.shrink(),
  //                     ),
  //                     title: Text("₹${ad.price}",
  //                         style: TextStyle(fontWeight: FontWeight.bold)),
  //                     subtitle: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         Text(ad.description,
  //                             maxLines: 1, overflow: TextOverflow.ellipsis),
  //                         Text(ad.location,
  //                             style: TextStyle(color: Colors.grey)),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //               );
  //             },
  //           );
  //         } else if (state is AdvertisementLoading) {
  //           return const Center(child: CircularProgressIndicator());
  //         } else {
  //           return const Center(child: Text("No ads found."));
  //         }
  //       },
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
        leading: IconButton(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.arrow_back)),
        title: Text(widget.categoryTitle, style: AppTextstyle.appbarText),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              // AppBar actions -> onTap:
              onTap: () async {
                final result = await context.push('/car-filter');
                if (result is Map<String, dynamic>) {
                  setState(() {
                    _filters = result; // save selected filters
                    _page = 1;
                    _hasMore = true;
                    _categoryAds.clear();
                  });
                  await _fetchCategoryAds(); // reload with filters
                }
              },

              child: Image.asset('assets/images/filter.png'),
            ),
          ),
        ],
      ),
      body: _buildCategoryListView(),
    );
  }

  Widget _buildCategoryListView() {
    if (_categoryAds.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_categoryAds.isEmpty) {
      return const Center(child: Text("No ads found."));
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _page = 1;
          _hasMore = true;
          _categoryAds.clear();
        });
        await _fetchCategoryAds();
      },
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _categoryAds.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < _categoryAds.length) {
            final ad = _categoryAds[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Card(
                color: AppColors.whiteColor,
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ad.images.isNotEmpty
                        ? Image.network(ad.images[0],
                            width: 60, height: 60, fit: BoxFit.cover)
                        : const SizedBox.shrink(),
                  ),
                  title: Text("₹${ad.price}",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ad.description,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(ad.location,
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }
}
