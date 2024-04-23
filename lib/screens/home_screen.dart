import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quinto_assignment7/helper/geohelper.dart';
import 'package:quinto_assignment7/screens/location_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final initPos = const LatLng(15.987779581934928, 120.57321759799687);

  late GoogleMapController mapController;

  late final Set<Marker> markers = {};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    GeoHelper.instance.permissionEnabled();
  }

  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          r"I'm the map",
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) {
                    return ListLocationScreen(refresh: refresh);
                  },
                ),
              );
            },
            icon: const Icon(Icons.list),
          ),
        ],
      ),
      body: FutureBuilder(
        future: FirebaseFirestore.instance.collection('locations').get(),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
              ),
            );
          }

          final docs = snapshot.data!.docs;
          markers.clear();
          for (var e in docs) {
            markers.add(
              Marker(
                markerId: MarkerId(e.id),
                position: LatLng(
                  e['latitude'],
                  e['longitude'],
                ),
              ),
            );
          }

          return Mapper(
            markers: markers,
          );
        },
      ),
    );
  }

  void _addMarker(LatLng pos) {
    final marker = Marker(
      markerId: MarkerId(UniqueKey().toString()),
      position: pos,
    );
    final cameraPos = CameraPosition(target: pos, zoom: 13);

    setState(() {
      markers.add(marker);
      mapController.animateCamera(CameraUpdate.newCameraPosition(cameraPos));
    });

    _enterLocDetails(marker);
  }

  Future<void> _enterLocDetails(Marker m) async {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    final isSaved = await showModalBottomSheet(
      enableDrag: false,
      isDismissible: false,
      context: context,
      builder: (context) => _ModalLocation(
        titleController: titleController,
        descController: descController,
        marker: m,
      ),
    );

    if (!isSaved) {
      setState(() {
        markers.remove(m);
      });
    }
  }
}

class Mapper extends StatefulWidget {
  const Mapper({super.key, required this.markers});

  final Set<Marker> markers;

  @override
  State<Mapper> createState() => _MapperState();
}

class _MapperState extends State<Mapper> {
  final initPos = const LatLng(15.987779581934928, 120.57321759799687);

  late GoogleMapController mapController;

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: (controller) => mapController = controller,
      mapType: MapType.normal,
      zoomControlsEnabled: true,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      initialCameraPosition: CameraPosition(
        target: initPos,
        zoom: 10,
      ),
      onTap: (pos) {
        _addMarker(pos);
      },
      markers: widget.markers,
    );
  }

  void _addMarker(LatLng pos) {
    final marker = Marker(
      markerId: MarkerId(UniqueKey().toString()),
      position: pos,
    );
    final cameraPos = CameraPosition(target: pos, zoom: 13);

    setState(() {
      widget.markers.add(marker);
      mapController.animateCamera(CameraUpdate.newCameraPosition(cameraPos));
    });

    _enterLocDetails(marker);
  }

  Future<void> _enterLocDetails(Marker m) async {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    final isSaved = await showModalBottomSheet(
      enableDrag: false,
      isDismissible: false,
      context: context,
      builder: (context) => _ModalLocation(
        titleController: titleController,
        descController: descController,
        marker: m,
      ),
    );

    if (!isSaved) {
      setState(() {
        widget.markers.remove(m);
      });
    }
  }
}

class _ModalLocation extends StatefulWidget {
  const _ModalLocation({
    super.key,
    required this.titleController,
    required this.descController,
    required this.marker,
  });

  final TextEditingController titleController;
  final TextEditingController descController;
  final Marker marker;

  @override
  State<_ModalLocation> createState() => _ModalLocationState();
}

class _ModalLocationState extends State<_ModalLocation> {
  String btnMsg = 'Save';
  bool isSaving = false;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Enter location details:',
                style: TextStyle(
                  fontSize: 14.0,
                ),
              ),
              IconButton(
                onPressed: isSaving
                    ? null
                    : () {
                        Navigator.pop(context, false);
                      },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          gap,
          TextField(
            controller: widget.titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
            ),
          ),
          gap,
          TextField(
            controller: widget.descController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
            ),
            maxLines: 4,
          ),
          gap,
          ElevatedButton(
            onPressed: isSaving
                ? null
                : () async {
                    final pos = widget.marker.position;

                    setState(() {
                      btnMsg = 'Saving...';
                    });

                    await FirebaseFirestore.instance
                        .collection('locations')
                        .doc(widget.marker.markerId.value)
                        .set({
                      'longitude': pos.longitude,
                      'latitude': pos.latitude,
                      'title': widget.titleController.text,
                      'description': widget.descController.text,
                    });

                    Navigator.pop(context, true);
                  },
            child: Text(btnMsg),
          ),
        ],
      ),
    );
  }
}
