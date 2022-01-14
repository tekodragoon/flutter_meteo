import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_meteo/Temperature.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart';
import 'package:geocoder/geocoder.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'my_flutter_app_icons.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MeteoApp());
}

class MeteoApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Meteo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Home(title: 'Météo'),
    );
  }
}

class Home extends StatefulWidget {
  Home({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  String prefKey = "savedCity";
  List<String> cities = [];
  String selectedCity;
  Coordinates selectedCityCoord;
  Temperature temperature;
  Location location;
  LocationData locationData;
  Stream<LocationData> stream;

  @override
  void initState() {
    super.initState();
    getPref();
    location = Location();
    //getFirstLocation();
    listenToStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          centerTitle: true,
        ),
        drawer: Drawer(
          child: Container(
            color: Colors.lightBlueAccent[200],
            child: ListView.builder(
                itemCount: cities.length + 2,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return DrawerHeader(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            appText('Mes villes', size: 22.0),
                            ElevatedButton(
                              onPressed: addCity,
                              child: appText('Ajouter une ville',color: Colors.white),
                            )
                          ],
                        )
                    );
                  } else if (i == 1) {
                    return ListTile(
                      title: appText('Ma position'),
                      onTap: () {
                        setState(() {
                          selectedCity = null;
                          selectedCityCoord = null;
                          getLocation();
                          Navigator.pop(context);
                        });
                      },
                    );
                  } else {
                    return ListTile(
                      onTap: () {
                        setState(() {
                          selectedCity = cities[i - 2];
                          coordFromCityName();
                          Navigator.pop(context);
                        });
                      },
                      trailing: IconButton(
                        icon: Icon(
                            Icons.delete,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          delete(cities[i-2]);
                        },
                      ),
                      title: appText(cities[i - 2], color: Colors.blue[900]),
                    );
                  }
                }
            ),
          ),
        ),
        body: temperature == null
            ?
        Center(child: appText(selectedCity == null ? "Ville actuelle: " : selectedCity, factor: 2.0, color: Colors.blueAccent[700]),)
            :
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: getBackground(),
                  fit: BoxFit.cover
                )
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  appText(
                  selectedCity == null ? "Ville actuelle: " : selectedCity,
                  factor: 2.0,
                  color: Colors.white
                  ),
                  appText(temperature.description, style: FontStyle.normal),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      //Image.network('http://openweathermap.org/img/wn/${temperature.icon}@2x.png'),
                      Image(image: getIcon()),
                      appText('${temperature.temp.toInt()} °C'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      extra('${temperature.min.toInt()} °C', MyFlutterApp.down),
                      extra('${temperature.max.toInt()} °C', MyFlutterApp.up),
                      extra('${temperature.pressure.toInt()}', MyFlutterApp.temperatire),
                      extra('${temperature.humidity.toInt()}%', MyFlutterApp.drizzle),
                    ],
                  )
                ],
              ),
            )
    );
  }

  Text appText(String data, {color: Colors.black, size: 20.0, factor: 1.0, weight: FontWeight.bold, style: FontStyle.italic, align: TextAlign.center}) {
    return Text(
      data ?? '',
      textScaleFactor: factor,
      textAlign: align,
      style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          fontStyle: style
      ),
    );
  }

  Future<Null> addCity() async {
    return showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext ctx) {
          return SimpleDialog(
            contentPadding: EdgeInsets.all(20.0),
            title: appText('Ajouter une ville', size: 22.0, color: Colors.blueAccent[700]),
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Ville: '),
                onSubmitted: (String data) {
                  setPref(data);
                  Navigator.pop(ctx);
                },
              )
            ],
          );
        }
    );
  }

  void getPref() async {
    SharedPreferences sharedPref = await SharedPreferences.getInstance();
    List<String> diskList = sharedPref.getStringList(prefKey);
    if (diskList != null) {
      setState(() {
        cities = diskList;
      });
    }
  }

  void setPref(String data) async {
    SharedPreferences sharedPref = await SharedPreferences.getInstance();
    setState(() {
      cities.add(data);
    });
    await sharedPref.setStringList(prefKey, cities);
  }

  void delete(String data) async {
    SharedPreferences sharedPref = await SharedPreferences.getInstance();
    setState(() {
      cities.remove(data);
    });
    await sharedPref.setStringList(prefKey, cities);
  }

  getLocation() async {
    try {
      locationData = await location.getLocation();
      print('pos: ${locationData.latitude} / ${locationData.longitude}');
      locationToCityName();
    } catch (e) {
      print('error: $e');
    }
  }

  listenToStream() {
    stream = location.onLocationChanged;
    stream.listen((newPos) {
      if(locationData == null || (locationData.longitude != newPos.longitude &&
      locationData.latitude != newPos.latitude)) {
        print("new position: ${newPos.latitude} / ${newPos.longitude}");
        setState(() {
          locationData = newPos;
          locationToCityName();
        });
      }
    });
  }

  locationToCityName() async {
    if(locationData != null) {
      final coordinates = Coordinates(locationData.latitude, locationData.longitude);
      var cityName = await Geocoder.local.findAddressesFromCoordinates(coordinates);
      var first = cityName.first;
      print(first.locality);
      setState(() {
        selectedCity = first.locality;
      });
      apiCall();
    }
  }

  coordFromCityName() async {
    if(selectedCity != null) {
      var adress = await Geocoder.local.findAddressesFromQuery(selectedCity);
      var first = adress.first;
      setState(() {
        print('${first.coordinates}');
        selectedCityCoord = first.coordinates;
        apiCall();
      });
    }
  }

  apiCall() async {
    double lat, lon;
    if(selectedCityCoord != null) {
      lat = selectedCityCoord.latitude;
      lon = selectedCityCoord.longitude;
    } else if (locationData != null) {
      lat = locationData.latitude;
      lon = locationData.longitude;
    }

    if(lat != null && lon != null) {
      final key = "-------";
      //String lang = "&lang=${Localizations.localeOf(context).languageCode}";
      String lang = "&lang=fr";
      String url = "https://community-open-weather-map.p.rapidapi.com/weather?";
      String coor = "lat=$lat&lon=$lon";
      String unit = "&units=metric";
      String all = url + coor + unit + lang;
      Map <String,String> header = {
        "x-rapidapi-key": key,
        "x-rapidapi-host": "community-open-weather-map.p.rapidapi.com"
      };
      final response = await http.get(all,headers: header);
      if (response.statusCode == 200) {
        //print(response.body);
        Map body = json.decode(response.body);
        setState(() {
          temperature = Temperature(body);
          print(temperature.description);
        });
      }
      else {
        print("http status: ${response.statusCode}");
      }
    }
  }

  AssetImage getBackground() {
    print(temperature.icon);
    String background = "assets/B_${temperature.icon}.png";
    return AssetImage(background);
  }

  AssetImage getIcon() {
    String icon = temperature.icon.replaceAll('d', '').replaceAll('n', '');
    return AssetImage('assets/$icon.png');
  }

  Column extra(String data, IconData iconData) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Icon(iconData, color: Colors.white, size: 32.0,),
        appText(data)
      ],
    );
  }
}
