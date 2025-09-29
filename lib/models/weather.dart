import 'package:flutter/material.dart';

class WeatherDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> weatherData;

  WeatherDetailsScreen({required this.weatherData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${weatherData['name']} Weather")),
      body: Column(
        children: [
          Text("Temperature: ${weatherData['main']['temp']}°C"),
          Text("Humidity: ${weatherData['main']['humidity']}%"),
          Text("Wind Speed: ${weatherData['wind']['speed']} m/s"),
          Text("Description: ${weatherData['weather'][0]['description']}"),
        ],
      ),
    );
  }
}
