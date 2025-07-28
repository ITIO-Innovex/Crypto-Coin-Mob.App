import 'package:flutter/material.dart';

class SwapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Swap'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You Pay', style: TextStyle(fontWeight: FontWeight.bold)),
            Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('BNB')),
                title: Text('BNB'),
                trailing: Text('0.01 ≈ 6.2470 USD'),
              ),
            ),
            SizedBox(height: 20),
            Text('You Receive', style: TextStyle(fontWeight: FontWeight.bold)),
            Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('USDT')),
                title: Text('USDT'),
                trailing: Text('6.7345108344 ≈ 6.7345108344 USD'),
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Fee: 0.25581 USDT'),
                Text('1 BNB = 673.4510834 (198.8 USD)'),
              ],
            ),
            Spacer(),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz),
                  SizedBox(width: 10),
                  Expanded(
                    child: Slider(
                      value: 0.5,
                      onChanged: (value) {},
                      activeColor: Colors.blue,
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios),
                ],
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {},
                child: Text('Slide to Swap'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}