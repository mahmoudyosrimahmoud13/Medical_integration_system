import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:healthhub/cubit/search/search_cubit.dart';
import 'package:healthhub/helpers/helper_methods.dart';
import 'package:healthhub/screens/home/notifications.dart';
import 'package:healthhub/widgets/custom_loading.dart';
import 'package:healthhub/widgets/fillter_modal.dart';
import 'package:healthhub/widgets/generic_texfield.dart';
import 'package:healthhub/widgets/sort_widget.dart';
import 'package:intl/intl.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.name, required this.url});
  final String name;
  final String url;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  Map<String, dynamic> _keys = {'area': {}, 'governrate': {}, 'speciality': {}};

  void _showModal() {
    showModalBottomSheet(
      showDragHandle: true,
      context: context,
      builder: (context) {
        return Container(
            height: 400,
            width: double.infinity,
            child: FillterModal(
              onfillter: (keys) {
                setState(() {
                  _keys = keys;
                });
                print(keys);
              },
            ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: SafeArea(
            child: Column(
          children: [
            SizedBox(
              height: size.height * 0.34,
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // user name:
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                CircleAvatar(
                                  backgroundImage: NetworkImage(widget.url),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  'Hi, ${widget.name}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall!
                                      .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            // Date:
                            Text(
                              DateFormat.yMMMd().format(DateTime.now()),
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimary
                                    .withAlpha(200),
                              ),
                            )
                          ],
                        )
                        //Notification bell
                        ,
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withAlpha(150),
                          ),
                          child: IconButton(
                              onPressed: () {
                                navigateTo(toPage: Notifications());
                              },
                              icon: Icon(
                                Icons.notifications,
                                color: Theme.of(context).colorScheme.onPrimary,
                              )),
                        )
                      ],
                    )
                    // search Bar
                    ,
                    const SizedBox(
                      height: 12,
                    ),
                    Form(
                      key: _key,
                      child: GenericTextField(
                        textEditingController: _searchController,
                        hint: 'Find your doctor.',
                        radius: 20,
                        alpha: 150,
                        iconButton: IconButton(
                          onPressed: () {
                            if (_key.currentState!.validate()) {
                              BlocProvider.of<SearchCubit>(context)
                                  .serchDoctorsWithName(
                                      name: _searchController.text,
                                      area: _keys['area']['id'],
                                      governrate: _keys['governrate']['id'],
                                      specialtie: _keys['speciality']['id']);
                            }
                          },
                          icon: Icon(
                            Icons.search,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        validator: (value) {
                          if (_keys['speciality']['id'] == null) {
                            return 'Please choose specialty';
                          }
                          print(value!.length);
                          if (value.length < 3) {
                            return 'Enter the name.';
                          }
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    // Filtters
                    SingleChildScrollView(
                      scrollDirection: axisDirectionToAxis(AxisDirection.right),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          TextButton.icon(
                              onPressed: _showModal,
                              icon: Icon(Icons.filter_alt_outlined,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary),
                              label: Text(
                                'Filtter by',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary),
                              )),
                          _keys['governrate']['key'] == null
                              ? const SizedBox.shrink()
                              : SortWidget(
                                  text: _keys['governrate']['key'],
                                ),
                          const SizedBox(
                            width: 5,
                          ),
                          _keys['area']['key'] == null
                              ? const SizedBox.shrink()
                              : SortWidget(
                                  text: _keys['area']['key'],
                                ),
                          const SizedBox(
                            width: 5,
                          ),
                          _keys['speciality']['name'] == null
                              ? const SizedBox.shrink()
                              : SortWidget(
                                  text: _keys['speciality']['name'],
                                )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Body
            Expanded(
                child: Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onPrimary,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30))),
              child: SingleChildScrollView(
                child: _keys['speciality']['name'] != null
                    ? BlocBuilder<SearchCubit, SearchState>(
                        builder: (context, state) {
                          if (state is SearchSuccess) {
                            return Column(
                              children: [...state.cards],
                            );
                          } else {
                            return Expanded(
                              child: Container(
                                  width: double.infinity,
                                  height: 400,
                                  child: CustomLoading()),
                            );
                          }
                        },
                      )
                    : Container(
                        padding: EdgeInsets.all(10),
                        height: 400,
                        width: double.infinity,
                        child: SvgPicture(
                            SvgAssetLoader('assets/placeholders/Search.svg')),
                      ),
              ),
            ))
          ],
        )));
  }
}
