import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class Opinion extends StatelessWidget {
  const Opinion({super.key, required this.name, required this.comment});
  final String name;
  final String comment;

  @override
  Widget build(BuildContext context) {
    final _colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      child: Container(
        height: double.infinity,
        width: 150,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            alignment: Alignment.topLeft,
            width: double.infinity,
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12)),
                color: _colors.error.withAlpha(100)),
            child: Text(
              name,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge!
                  .copyWith(color: _colors.onPrimary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comment),
                RatingBar.builder(
                  initialRating: 3,
                  itemSize: 10,
                  allowHalfRating: true,
                  ignoreGestures: false,
                  itemBuilder: (context, index) => Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (value) {},
                ),
              ],
            ),
          )
        ]),
      ),
    );
  }
}
