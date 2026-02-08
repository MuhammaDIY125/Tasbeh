import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'counter_cubit.dart';

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CounterCubit>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: cubit.increment,
          child: Stack(
            children: [
              Positioned(
                right: 8,
                top: 8,
                child: IconButton(
                  onPressed: cubit.reset,
                  icon: const Icon(
                    Icons.restart_alt_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
              Center(
                child: BlocBuilder<CounterCubit, int>(
                  builder: (context, counter) {
                    return Text(
                      '$counter',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
