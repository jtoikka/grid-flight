library River;

import 'dart:math';
import 'dart:typed_data';

class River {
    static const NOISERESOLUTION = 512;
    static const FREQUENCY = 0.015;
    static const AMPLITUDE = 5.0;

    Uint8List noiseSequence;

    River() {
        generateNoiseSequence();
    }

    void generateNoiseSequence() {
        var rng = new Random();
        var temp = new List();
        for (int i = 0; i < NOISERESOLUTION; i++) {
            var randValue = rng.nextInt(5);
            var shifted = randValue / 4.0 * 255.0;
            temp.add(shifted.toInt());
            temp.add(0);
            temp.add(0);
        }
        noiseSequence = new Uint8List.fromList(temp);
    }

    double _cosineInterpolate(double f, double c, double mu) {
        double mu2 = (1.0 - cos(mu * PI)) * 0.5;
        return (f * (1.0 - mu2) + c * mu2);
    }

    double _noise(double dist) {
        double delta = dist * FREQUENCY;
        int low = delta.floor();
        int high = delta.ceil();
        int r1 = noiseSequence[low * 3]; // Multiply by 3 as only every third
                                         // place contains a value ([r]gb)
        int r2 = noiseSequence[high * 3];
        double noise = _cosineInterpolate(r1.toDouble(), r2.toDouble(), (delta - low));
        noise /= 255.0;
        return noise * AMPLITUDE;
    }
}