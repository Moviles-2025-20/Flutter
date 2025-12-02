import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

class NfcService {
  static final NfcService _instance = NfcService._internal();
  factory NfcService() => _instance;
  NfcService._internal();

  Future<void> startSession(GlobalKey<NavigatorState> navigatorKey) async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) return;

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        debugPrint('NFC Tag Discovered: ${tag.data}');
        
        Ndef? ndef = Ndef.from(tag);
        if (ndef == null) return;

        final message = ndef.cachedMessage;
        if (message != null) {
          for (var record in message.records) {
            // Check for text/plain payload as requested
            try {
              String payload = String.fromCharCodes(record.payload);
              debugPrint('Payload: $payload');
              if (payload.contains('com.mobileclass.parchandes')) {
                 navigatorKey.currentState?.pushNamed(
                  '/wishMeLuck',
                  arguments: {'autoTrigger': true},
                );
                return; // Trigger only once
              }
            } catch (e) {
              debugPrint('Error decoding payload: $e');
            }
          }
        }
      },
    );
  }

  Future<void> stopSession() async {
    await NfcManager.instance.stopSession();
  }

  Future<void> writeTag() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) return;

    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      try {
        Ndef? ndef = Ndef.from(tag);
        if (ndef == null || !ndef.isWritable) {
          debugPrint('Tag is not ndef writable');
          NfcManager.instance.stopSession(errorMessage: 'Tag is not ndef writable');
          return;
        }

        NdefMessage message = NdefMessage([
          NdefRecord.createMime(
              'text/plain', Uint8List.fromList('com.mobileclass.parchandes'.codeUnits)),
        ]);

        await ndef.write(message);
        NfcManager.instance.stopSession(alertMessage: 'Successfully wrote AAR!');
      } catch (e) {
        NfcManager.instance.stopSession(errorMessage: e.toString());
      }
    });
  }
}

