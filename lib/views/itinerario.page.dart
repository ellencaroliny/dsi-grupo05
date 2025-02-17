import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/models/itinerario_model.dart';
import 'package:flutter_application_1/services/firestore/itinerarios.service.dart';
import 'package:flutter_application_1/widgets/itinerario_card.dart';
import 'package:flutter_application_1/views/criar_itinerario.page.dart';

class ItinerariosPage extends StatelessWidget {
  final String userId;

  const ItinerariosPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final itinerariosService = ItinerariosService(userId);

    return Scaffold(
      backgroundColor: Colors.white, // Cor de fundo
      appBar: AppBar(
        title: const Text(
          'Itinerários',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushNamed(context, '/menu');
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: itinerariosService.getItinerariosStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('Nenhum itinerário encontrado.',
                    style: TextStyle(fontFamily: 'Poppins')));
          }

          final itinerarios = snapshot.data!.docs.map((doc) async {
            var itinerarioData = doc.data() as Map<String, dynamic>;
            var itinerarioId = doc.id;

            List<ItinerarioItem> locais = [];
            var locaisSnapshot =
                await itinerariosService.getLocaisByItinerarioId(itinerarioId);

            for (var localDoc in locaisSnapshot.docs) {
              var localData = localDoc.data() as Map<String, dynamic>;
              locais.add(ItinerarioItem.fromFirestore(localData));
            }

            return ItinerarioModel.fromFirestore(itinerarioData, locais);
          }).toList();

          return FutureBuilder(
            future: Future.wait(itinerarios),
            builder: (context, futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (futureSnapshot.hasError) {
                return Center(
                    child: Text("Erro ao carregar itinerários: ${futureSnapshot.error}",
                        style: TextStyle(fontFamily: 'Poppins')));
              }

              if (!futureSnapshot.hasData || futureSnapshot.data!.isEmpty) {
                return const Center(
                    child: Text('Nenhum itinerário encontrado.',
                        style: TextStyle(fontFamily: 'Poppins')));
              }

              final itinerarios = futureSnapshot.data as List<ItinerarioModel>;

              return ListView.builder(
                itemCount: itinerarios.length,
                itemBuilder: (context, index) {
                  final itinerario = itinerarios[index];
                  return Dismissible(
                    key: Key(itinerario.id ?? ''),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) async {
                      await itinerariosService.deleteItinerario(itinerario.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Itinerário '${itinerario.titulo}' excluído."),
                        ),
                      );
                    },
                    child: GestureDetector(
                      onTap: () {
                        // Handle card tap
                      },
                      child: ItineraryCard(itinerario: itinerario),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateItinerarioPage(userId: userId),
            ),
          );
        },
        backgroundColor: const Color(0xFF01A897),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}