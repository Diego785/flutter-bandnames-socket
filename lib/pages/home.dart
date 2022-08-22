import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart';

import 'package:band_names/models/band.dart';
import 'package:band_names/services/socket_service.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Band> bands = [
    /*  Band(id: '1', name: 'Metallica', votes: 5),
    Band(id: '2', name: 'Queen', votes: 1),
    Band(id: '3', name: 'Héroes del Silencio', votes: 2),
    Band(id: '4', name: 'Bon Jovi', votes: 5),*/
  ];

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.on('active-bands', _handleActiveBands);
    super.initState();
  }

  _handleActiveBands(dynamic payload) {
    this.bands = (payload as List).map((band) => Band.fromMap(band)).toList();
    setState(() {});
  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context);
    socketService.socket.off('active-bands');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Band Names',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 10),
            child: //TODO: Ternario
                (socketService.serverStatus == ServerStatus.Online)
                    ? Icon(
                        Icons.check_circle,
                        color: Colors.blue[300],
                      )
                    : Icon(
                        Icons.offline_bolt,
                        color: Colors.red,
                      ),
          ),
        ],
      ),
      body: Column(
        children: [
          _showGraph(),
          Expanded(
            child: ListView.builder(
              itemCount: bands.length,
              itemBuilder: (context, i) => _bandTile(bands[i]),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 1,
        onPressed: () => addNewBand(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _bandTile(Band banda) {
    final socketService = Provider.of<SocketService>(context, listen: false);
    return Dismissible(
      key: Key(banda.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) =>
          socketService.socket.emit('delete-band', {'id': banda.id}),
      background: Container(
        padding: EdgeInsets.only(left: 8.0),
        color: Colors.red,
        child: const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Delete band',
              style: TextStyle(color: Colors.white),
            )),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(banda.name.substring(0, 2)),
        ),
        title: Text(banda.name),
        trailing: Text(
          banda.votes.toString(),
          style: const TextStyle(fontSize: 20),
        ),
        onTap: () => socketService.socket.emit('vote-band', {'id': banda.id}),
      ),
    );
  }

  addNewBand() {
    final textController = new TextEditingController();

    if (Platform.isAndroid) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('New Band Name:'),
          content: TextField(
            controller: textController,
          ),
          actions: <Widget>[
            MaterialButton(
              elevation: 5,
              child: const Text('Add'),
              textColor: Colors.blue,
              onPressed: () => addBandToList(textController.text),
            ),
          ],
        ),
      );
    } else {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text('New Band Name'),
          content: CupertinoTextField(
            controller: textController,
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text('Add'),
              onPressed: () => addBandToList(textController.text),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text('Dismiss'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  void addBandToList(String name) {
    if (name.length > 1) {
      // Podemos agregar
      // Emitir: add-band
      // { name: name }
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.socket.emit('add-band', {'name': name});
    }
    Navigator.pop(context);
  }

  //MOOSTRAR GRÁFICA
  Widget _showGraph() {
    Map<String, double> dataMap = new Map();
    //dataMap.putIfAbsent('Flutter', () => 5);
    //dataMap.putIfAbsent('React', () => 3);
    //dataMap.putIfAbsent('Xamarin', () => 2);
    //dataMap.putIfAbsent('Ionic', () => 2);
    bands.forEach((band) {
      dataMap.putIfAbsent(band.name, () => band.votes.toDouble());
    });
    final List<Color> colorList = [
      Colors.blue.shade50,
      Colors.blue.shade200,
      Colors.pink.shade50,
      Colors.pink.shade200,
      Colors.yellow.shade50,
      Colors.yellow.shade200,
    ];
    return Container(
      padding: EdgeInsets.only(top: 10),
      width: double.infinity,
      height: 200,
      child: PieChart(
        dataMap: dataMap,
        animationDuration: Duration(milliseconds: 800),
        chartLegendSpacing: 32,
        chartRadius: MediaQuery.of(context).size.width / 3.2,
        colorList: colorList,
        initialAngleInDegree: 0,
        chartType: ChartType.ring,
        ringStrokeWidth: 32,
        centerText: "HYBRID",
        legendOptions: LegendOptions(
          showLegendsInRow: false,
          legendPosition: LegendPosition.right,
          showLegends: true,
          legendShape: BoxShape.circle,
          legendTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        chartValuesOptions: ChartValuesOptions(
          showChartValueBackground: true,
          showChartValues: true,
          showChartValuesInPercentage: false,
          showChartValuesOutside: false,
          decimalPlaces: 1,
        ),
        // gradientList: ---To add gradient colors---
        // emptyColorGradient: ---Empty Color gradient---
      ),
    );
  }
}
