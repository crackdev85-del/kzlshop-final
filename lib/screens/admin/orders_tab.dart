import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:moegyi/constants.dart';
import 'package:moegyi/providers/order_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'order_detail_screen.dart';

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(ordersCollectionPath)
          .orderBy('dateTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('တစ်ခုခုမှားယွင်းနေသည်: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('အော်ဒါများ မတွေ့ပါ။'));
        }

        final orderDocs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: orderDocs.length,
          itemBuilder: (context, index) {
            return AdminOrderCard(orderSnapshot: orderDocs[index]);
          },
        );
      },
    );
  }
}

class AdminOrderCard extends StatefulWidget {
  final DocumentSnapshot orderSnapshot;

  const AdminOrderCard({super.key, required this.orderSnapshot});

  @override
  State<AdminOrderCard> createState() => _AdminOrderCardState();
}

class _AdminOrderCardState extends State<AdminOrderCard> {
  var _expanded = false;

  void _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            child: const Text('မလုပ်တော့ပါ'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          TextButton(
            child: const Text('အတည်ပြုသည်'),
            onPressed: () {
              onConfirm();
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderData = widget.orderSnapshot.data() as Map<String, dynamic>;
    final orderId = widget.orderSnapshot.id;
    final List<dynamic> products = orderData['products'] ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      child: Column(
        children: [
          ListTile(
            title: UserInfoWidget(userId: orderData['userId']),
            subtitle: Text(
                'စုစုပေါင်း: ${orderData['totalAmount'].toStringAsFixed(2)} ကျပ်\nမှာယူသည့်အချိန်: ${DateFormat('dd/MM/yy hh:mm a').format((orderData['dateTime'] as Timestamp).toDate())}'),
            isThreeLine: true,
            onTap: () {
               setState(() {
                  _expanded = !_expanded;
                });
            },
            trailing: IconButton(
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('မှာယူထားသော ပစ္စည်းများ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...products.map((prod) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('${prod['name']} (x${prod['quantity']})')),
                          Text('${(prod['price']).toStringAsFixed(2)} ကျပ်'),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                        label: const Text('လက်ခံမည်', style: TextStyle(color: Colors.green)),
                        onPressed: () {
                          _showConfirmationDialog(
                            context: context,
                            title: 'အော်ဒါ လက်ခံခြင်း',
                            content: 'ဤအော်ဒါကို လက်ခံလိုပါသလား?',
                            onConfirm: () {
                              Provider.of<OrderProvider>(context, listen: false)
                                  .updateOrderStatus(orderId, 'Processing');
                            },
                          );
                        },
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.edit_outlined, color: Theme.of(context).primaryColor),
                        label: Text('ပြင်ဆင်မည်', style: TextStyle(color: Theme.of(context).primaryColor)),
                        onPressed: () {
                           Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => OrderDetailScreen(orderSnapshot: widget.orderSnapshot),
                              ),
                            );
                        },
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text('ဖျက်သိမ်းမည်', style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          _showConfirmationDialog(
                            context: context,
                            title: 'အော်ဒါ ဖျက်သိမ်းခြင်း',
                            content: 'ဤအော်ဒါကို အမှန်တကယ် ဖျက်သိမ်းလိုပါသလား? ဤလုပ်ဆောင်ချက်ကို ပြန်လည်ပြင်ဆင်နိုင်မည်မဟုတ်ပါ။',
                            onConfirm: () {
                              FirebaseFirestore.instance
                                  .collection(ordersCollectionPath)
                                  .doc(orderId)
                                  .delete();
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class UserInfoWidget extends StatelessWidget {
  final String userId;

  const UserInfoWidget({super.key, required this.userId});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection(usersCollectionPath).doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('အသုံးပြုသူကို ရှာဖွေနေသည်...');
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Text('အသုံးပြုသူ မသိပါ', style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic));
        }
        final userData = snapshot.data!.data() as Map<String, dynamic>;

        final shopName = userData['shopName'] ?? 'ဆိုင်နာမည် မသိပါ';
        final phoneNumber = userData['phoneNumber'] ?? 'ဖုန်းနံပါတ် မရှိပါ';
        final location = userData['location'] ?? '';
        final locationUrl = location.isNotEmpty ? 'https://www.google.com/maps?q=${Uri.encodeComponent(location)}' : '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              shopName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(phoneNumber),
            const SizedBox(height: 4),
            if (location.isNotEmpty)
              InkWell(
                onTap: () => _launchURL(locationUrl),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Icon(Icons.location_on, color: Theme.of(context).primaryColor, size: 16),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              const Text('တည်နေရာ မရှိပါ'),
          ],
        );
      },
    );
  }
}
