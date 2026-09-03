import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostListingScreen extends StatefulWidget {
  const PostListingScreen({super.key});

  @override
  State<PostListingScreen> createState() => _PostListingScreenState();
}

class _PostListingScreenState extends State<PostListingScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Step 1 data
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String _listingType = 'rent';
  final _step1FormKey = GlobalKey<FormState>();

  // Step 2 data
  String? _selectedCity;
  final _subCityController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _addressController = TextEditingController();
  final _step2FormKey = GlobalKey<FormState>();

  static const List<String> _addisSubCities = [
    'Addis Ketema',
    'Akaky Kaliti',
    'Arada',
    'Bole',
    'Gullele',
    'Kirkos',
    'Kolfe Keranio',
    'Lideta',
    'Nifas Silk-Lafto',
    'Yeka',
    'Lemi Kura',
  ];

  static const List<String> _shegerSubCities = [
    'Burayu',
    'Eka Tafo',
    'Furi',
    'Gefersa Guji',
    'Gelan',
    'Gelan Guda',
    'Koye',
    'Kara Gida',
    'Mana Abichu',
    'Melka Nono',
    'Sebeta',
    'Sululta',
  ];

  // Step 3 data
  final List<XFile> _pickedPhotos = [];
  final ImagePicker _picker = ImagePicker();
  static const int _minPhotos = 3;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _subCityController.dispose();
    _neighborhoodController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() => _pickedPhotos.addAll(images));
    }
  }

  void _removePhoto(int index) {
    setState(() => _pickedPhotos.removeAt(index));
  }

  void _handleContinue() {
    if (_currentStep == 0) {
      if (_step1FormKey.currentState!.validate()) {
        setState(() => _currentStep += 1);
      }
    } else if (_currentStep == 1) {
      if (_step2FormKey.currentState!.validate()) {
        setState(() => _currentStep += 1);
      }
    } else if (_currentStep == 2) {
      if (_pickedPhotos.length < _minPhotos) {
        setState(
          () => _errorMessage = 'Please add at least $_minPhotos photos',
        );
        return;
      }
      _submitListing();
    }
  }

  Future<void> _submitListing() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      final combinedNeighborhood =
          '${_neighborhoodController.text.trim()}, ${_subCityController.text}, $_selectedCity';

      final listingResponse = await supabase
          .from('listings')
          .insert({
            'owner_id': userId,
            'title': _titleController.text.trim(),
            'description': _descriptionController.text.trim(),
            'price': double.parse(_priceController.text),
            'listing_type': _listingType,
            'neighborhood': combinedNeighborhood,
            'address': _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
          })
          .select()
          .single();

      final listingId = listingResponse['id'] as String;

      for (var i = 0; i < _pickedPhotos.length; i++) {
        final photo = _pickedPhotos[i];
        final bytes = await photo.readAsBytes();
        final fileExt = photo.name.split('.').last;
        final fileName =
            '$listingId/${DateTime.now().millisecondsSinceEpoch}_$i.$fileExt';

        await supabase.storage
            .from('listing-photos')
            .uploadBinary(fileName, bytes);

        final publicUrl = supabase.storage
            .from('listing-photos')
            .getPublicUrl(fileName);

        await supabase.from('media').insert({
          'listing_id': listingId,
          'media_type': 'photo',
          'url': publicUrl,
          'sort_order': i,
        });
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing posted successfully!')),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to post listing: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a Listing')),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _isSubmitting ? null : _handleContinue,
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep -= 1);
        },
        controlsBuilder: (context, details) {
          final isLastStep = _currentStep == 2;
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                FilledButton(
                  onPressed: details.onStepContinue,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isLastStep ? 'Post Listing' : 'Continue'),
                ),
                const SizedBox(width: 8),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: _isSubmitting ? null : details.onStepCancel,
                    child: const Text('Back'),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Basic details'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _step1FormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g. Modern 2-Bedroom Apartment',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Title is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe the property...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Description is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Price (ETB)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Price is required';
                      if (double.tryParse(v) == null)
                        return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'rent', label: Text('For Rent')),
                      ButtonSegment(value: 'sale', label: Text('For Sale')),
                    ],
                    selected: {_listingType},
                    onSelectionChanged: (selection) {
                      setState(() => _listingType = selection.first);
                    },
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Location'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _step2FormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCity,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Addis Ababa',
                        child: Text('Addis Ababa'),
                      ),
                      DropdownMenuItem(
                        value: 'Sheger City',
                        child: Text('Sheger City'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCity = value;
                        _subCityController.text = '';
                      });
                    },
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Select a city' : null,
                  ),
                  const SizedBox(height: 16),
                  if (_selectedCity != null)
                    DropdownButtonFormField<String>(
                      initialValue: _subCityController.text.isEmpty
                          ? null
                          : _subCityController.text,
                      decoration: const InputDecoration(
                        labelText: 'Sub-city',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          (_selectedCity == 'Addis Ababa'
                                  ? _addisSubCities
                                  : _shegerSubCities)
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() => _subCityController.text = value ?? '');
                      },
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Select a sub-city' : null,
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _neighborhoodController,
                    decoration: const InputDecoration(
                      labelText: 'Neighborhood / Area',
                      hintText: 'e.g. Bole Road, near Edna Mall',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Neighborhood is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address (optional)',
                      hintText: 'Street, landmark, etc.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Photos'),
            isActive: _currentStep >= 2,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add at least $_minPhotos photos (${_pickedPhotos.length} added)',
                ),
                const SizedBox(height: 12),
                if (_pickedPhotos.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _pickedPhotos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            FutureBuilder<Uint8List>(
                              future: _pickedPhotos[index].readAsBytes(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    snapshot.data!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              },
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => _removePhoto(index),
                                child: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.black54,
                                  child: Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickPhotos,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Add Photos'),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
