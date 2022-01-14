class Temperature {

  String main, description, icon;
  var temp, pressure, humidity, min, max;

  /*
  {"coord":{
      "lon":-122.4351,
      "lat":37.6523
   },
   "weather":[
       {"id":800,
       "main":"Clear",
       "description":"clear sky"
       ,"icon":"01n"
   }],
  "base":"stations",
  "main":{"temp":7.82,
          "feels_like":4.7,
          "temp_min":6.11,
          "temp_max":9.44,
          "pressure":1024,
          "humidity":65
          },
  "visibility":10000,
  "wind":{
      "speed":1.99,
      "deg":75
      },
  "clouds":{
      "all":1
  },
  "dt":1612531437,
  "sys":{
      "type":1,
      "id":5817,
      "country":"US",
      "sunrise":1612537777,
      "sunset":1612575477
      },
  "timezone":-28800,
  "id":5397765,
  "name":"South San Francisco",
  "cod":200
  }
   */

  Temperature(Map data) {
    List weather = data["weather"];
    Map weatherMap = weather.first;
    this.main = weatherMap["main"];
    this.description = weatherMap["description"];
    this.icon = weatherMap["icon"];
    Map mainMap = data["main"];
    this.temp = mainMap["temp"];
    this.min = mainMap["temp_min"];
    this.max = mainMap["temp_max"];
    this.pressure = mainMap["pressure"];
    this.humidity = mainMap["humidity"];
  }

}