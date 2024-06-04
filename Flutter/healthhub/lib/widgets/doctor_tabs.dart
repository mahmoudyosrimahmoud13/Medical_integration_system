import 'package:flutter/material.dart';
import 'package:healthhub/widgets/opinion.dart';

class DcotorTabs extends StatefulWidget {
  const DcotorTabs({super.key});

  @override
  State<DcotorTabs> createState() => _DcotorTabsState();
}

class _DcotorTabsState extends State<DcotorTabs> {
  final lis = [
    Opinion(name: 'sss', comment: 'it was amazing'),
    Opinion(name: 'lol', comment: 'bad'),
    Opinion(name: 'sss', comment: 'it was amazing'),
    Opinion(name: 'lol', comment: 'bad'),
    Opinion(name: 'sss', comment: 'it was amazing'),
    Opinion(name: 'lol', comment: 'bad'),
    Opinion(name: 'sss', comment: 'it was amazing'),
    Opinion(name: 'lol', comment: 'bad'),
  ];
  @override
  Widget build(BuildContext context) {
    final _textTheme = Theme.of(context).textTheme;
    final _colors = Theme.of(context).colorScheme;

    final _decoration = BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        color: _colors.primary.withAlpha(50));

    return DefaultTabController(
        length: 3,
        child: Scaffold(
          body: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(50),

                  borderRadius: BorderRadius.circular(50), // Creates border
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TabBar(
                    dividerHeight: 0,
                    indicator: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(50), // Creates border
                    ),
                    tabs: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('About',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('Adress',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('Prices',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary)),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Expanded(
                child: TabBarView(children: [
                  Container(
                    decoration: _decoration,
                  ),
                  Container(
                    decoration: _decoration,
                  ),
                  Container(
                    decoration: _decoration,
                  )
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.mode_comment_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 30,
                    ),
                    Text(
                      'Openions',
                      style: _textTheme.bodyLarge!.copyWith(
                          color: _colors.primary, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
              Container(
                decoration: _decoration,
                height: 150,
                child: ListView.builder(
                  itemBuilder: (context, index) => lis[index],
                  itemCount: lis.length,
                  scrollDirection: Axis.horizontal,
                ),
              )
            ],
          ),
        ));
  }
}
