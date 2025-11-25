// Generate a basic flutter app structure with a yellow cube in the center
import 'package:flutter/material.dart';

class CountdownConfigurator extends StatefulWidget {
  final VoidCallback continue_callback;

  const CountdownConfigurator({
    super.key,
    required this.continue_callback,
  });

  @override
  State<CountdownConfigurator> createState() => _CountdownConfiguratorState();
}

class _CountdownConfiguratorState extends State<CountdownConfigurator> {
  DateTime? date;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 100,
          height: 100,
          color: Colors.yellow,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Select a date for the Baby\'s Gender Reveal'),
              ElevatedButton(
                onPressed: () async {
                  // Open date picker and set date
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: date ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      date = pickedDate;
                    });
                  }
                },
                child: const Text('Select Date'),
              ),
              if (date != null)
                ElevatedButton(
                  onPressed: widget.continue_callback,
                  child: const Text('Confirm Date'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
