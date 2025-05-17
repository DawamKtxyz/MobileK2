// lib/screens/service_management_screen.dart
import 'package:flutter/material.dart';

class ServiceManagementScreen extends StatefulWidget {
  const ServiceManagementScreen({Key? key}) : super(key: key);

  @override
  State<ServiceManagementScreen> createState() => _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceNameController = TextEditingController();
  final _servicePriceController = TextEditingController();
  final _serviceDescriptionController = TextEditingController();
  
  // Mock services data
  final List<Map<String, dynamic>> _services = [
    {
      'name': 'Burst Fade',
      'price': 20000,
      'description': 'Potongan dengan fade di bagian samping dan belakang',
    },
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Layanan Saya'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Services list
            Expanded(
              child: _services.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.design_services,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada layanan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tambahkan layanan pertama Anda',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _services.length,
                      itemBuilder: (context, index) {
                        final service = _services[index];
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 0,
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.content_cut,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        service['name'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (service['description'] != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          service['description'],
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Rp ${service['price']}',
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            // Edit service
                                            _showEditServiceDialog(index);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[50],
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () {
                                            // Delete service
                                            _showDeleteConfirmation(index);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.red[50],
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddServiceDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Layanan'),
      ),
    );
  }

  void _showAddServiceDialog() {
    // Reset form controllers
    _serviceNameController.clear();
    _servicePriceController.clear();
    _serviceDescriptionController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Layanan'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _serviceNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Layanan',
                    hintText: 'Contoh: Burst Fade',
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Nama layanan tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _servicePriceController,
                  decoration: const InputDecoration(
                    labelText: 'Harga (Rp)',
                    hintText: 'Contoh: 20000',
                    prefixText: 'Rp ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harga tidak boleh kosong';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Harga harus berupa angka';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _serviceDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                    hintText: 'Deskripsi singkat tentang layanan',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  _services.add({
                    'name': _serviceNameController.text,
                    'price': int.parse(_servicePriceController.text),
                    'description': _serviceDescriptionController.text.isEmpty
                        ? null
                        : _serviceDescriptionController.text,
                  });
                });
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Layanan berhasil ditambahkan')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showEditServiceDialog(int index) {
    final service = _services[index];
    
    // Initialize form controllers with existing service data
    _serviceNameController.text = service['name'];
    _servicePriceController.text = service['price'].toString();
    _serviceDescriptionController.text = service['description'] ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Layanan'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _serviceNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Layanan',
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Nama layanan tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _servicePriceController,
                  decoration: const InputDecoration(
                    labelText: 'Harga (Rp)',
                    prefixText: 'Rp ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harga tidak boleh kosong';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Harga harus berupa angka';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _serviceDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  _services[index] = {
                    'name': _serviceNameController.text,
                    'price': int.parse(_servicePriceController.text),
                    'description': _serviceDescriptionController.text.isEmpty
                        ? null
                        : _serviceDescriptionController.text,
                  };
                });
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Layanan berhasil diperbarui')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(int index) {
    final service = _services[index];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Layanan'),
        content: Text(
          'Apakah Anda yakin ingin menghapus layanan "${service['name']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _services.removeAt(index);
              });
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Layanan berhasil dihapus')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}