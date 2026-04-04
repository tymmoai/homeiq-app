import 'package:homeiq/features/maintenance/screens/ai_fix_models.dart';

/// Helper class providing fallback data for the AI Fix Problem flow
/// when API calls fail or return empty results.
class AiFixFallbackData {
  AiFixFallbackData._();

  /// Get asset-specific fallback issue options when API call fails
  static List<String> getIssueOptions(
    Map<String, dynamic> asset,
    String assetName,
  ) {
    final assetType =
        (asset['type'] as String?)?.toLowerCase() ?? assetName.toLowerCase();
    if (assetType.contains('refrigerator') || assetType.contains('fridge')) {
      return [
        'Not cooling properly',
        'Making unusual humming or buzzing noises',
        'Ice buildup in freezer',
        'Water leaking on the floor',
        'Compressor runs constantly',
        'Door seal not closing properly',
      ];
    } else if (assetType.contains('tv') || assetType.contains('television')) {
      return [
        'Screen flickering or flashing',
        'No picture but has sound',
        'Not turning on or powering up',
        'Poor picture quality or color issues',
        'No sound or distorted audio',
        'Remote control not responding',
      ];
    } else if (assetType.contains('ac') ||
        assetType.contains('air conditioner')) {
      return [
        'Not cooling the room effectively',
        'Making loud or unusual noises',
        'Leaking water inside or outside',
        'Bad odor when running',
        'Turning on and off frequently',
        'Airflow is weak or inconsistent',
      ];
    } else if (assetType.contains('microwave')) {
      return [
        'Not heating food evenly',
        'Turntable not spinning',
        'Sparking inside the microwave',
        'Door not closing or latching properly',
        'Display or buttons not working',
        'Unusual burning smell when in use',
      ];
    } else if (assetType.contains('washer') || assetType.contains('washing')) {
      return [
        'Not draining water properly',
        'Excessive vibration during spin cycle',
        'Clothes not getting clean',
        'Water leaking from the machine',
        'Making grinding or banging noises',
        'Not starting or completing cycles',
      ];
    } else {
      return [
        'Not working properly',
        'Making unusual noises',
        'Not turning on',
        'Performance has degraded',
        'Unexpected shutdowns',
        'Physical damage or wear',
      ];
    }
  }

  /// Get fallback root cause analysis text when API call fails
  static String getSolution(
    Map<String, dynamic> asset,
    String assetName,
  ) {
    final assetType =
        (asset['type'] as String?)?.toLowerCase() ?? assetName.toLowerCase();
    if (assetType.contains('refrigerator') || assetType.contains('fridge')) {
      return '• Evaporator coils are dirty or frosted over, reducing cooling efficiency.\n'
          '• Door gasket is worn or not sealing properly, allowing cold air to escape.\n'
          '• Thermostat sensor is misaligned or malfunctioning, causing wrong temperature readings.\n'
          '• Condenser fan motor is partially failing, leading to poor heat dissipation.\n'
          '• Temperature control board may have a faulty circuit, affecting regulation.';
    } else if (assetType.contains('tv') || assetType.contains('television')) {
      return '• HDMI ports may have loose connections or accumulated dust.\n'
          '• Backlight LEDs could be failing, causing dim or uneven brightness.\n'
          '• Power supply board capacitors may be degraded, causing intermittent shutdowns.\n'
          '• Software/firmware may need updating to resolve performance issues.\n'
          '• Remote sensor window may be obstructed or the IR receiver could be faulty.';
    } else if (assetType.contains('ac') ||
        assetType.contains('air conditioner')) {
      return '• Air filter is clogged with dust, restricting airflow and reducing cooling.\n'
          '• Refrigerant levels may be low due to a slow leak in the system.\n'
          '• Condenser coils are dirty, reducing heat dissipation efficiency.\n'
          '• Thermostat calibration is off, causing incorrect temperature readings.\n'
          '• Drain line may be clogged, causing water leakage or humidity issues.';
    } else if (assetType.contains('microwave')) {
      return '• Turntable motor may be worn, causing uneven heating.\n'
          '• Door switch/latch mechanism could be misaligned or worn.\n'
          '• Magnetron output may be weakening, leading to longer cook times.\n'
          '• Interior waveguide cover may have food buildup affecting performance.\n'
          '• Control panel buttons may have intermittent contact issues.';
    } else if (assetType.contains('washer') || assetType.contains('washing')) {
      return '• Drum bearings may be worn, causing excessive noise during spin cycle.\n'
          '• Door gasket has mold or debris buildup, affecting seal quality.\n'
          '• Drain pump filter is clogged, causing slow drainage.\n'
          '• Water inlet valve may be partially blocked, reducing fill speed.\n'
          '• Detergent dispenser may need cleaning to prevent residue buildup.';
    } else {
      return '• Regular inspection and cleaning is recommended to maintain optimal performance.\n'
          '• Check all connections and power supply for any loose or damaged components.\n'
          '• Filters or vents may be blocked, reducing efficiency.\n'
          '• Moving parts may need lubrication or replacement if worn.\n'
          '• Consider scheduling a professional inspection for a thorough diagnosis.';
    }
  }

  /// Get fallback DIY troubleshooting steps when API call fails
  static List<DiyStep> getDiySteps(
    Map<String, dynamic> asset,
    String assetName,
  ) {
    final assetType =
        (asset['type'] as String?)?.toLowerCase() ?? assetName.toLowerCase();

    if (assetType.contains('tv') || assetType.contains('television')) {
      return [
        DiyStep(
          title: 'Check power and connections',
          description:
              'Verify the TV is receiving proper power and all cables are securely connected.',
          instructions: [
            'Ensure the power cord is firmly plugged into the outlet and the TV.',
            'Check all HDMI, antenna, and audio cables for loose connections.',
            'Try a different power outlet to rule out outlet issues.',
          ],
          safetyNote:
              'Unplug the TV before inspecting or re-seating any cables.',
          duration: '5-10 minutes',
          riskLevel: 'Low',
          toolsNeeded: ['Flashlight', 'Spare HDMI cable (optional)'],
        ),
        DiyStep(
          title: 'Reset and update software',
          description:
              'A software reset can resolve many display and performance issues.',
          instructions: [
            'Unplug the TV from power and wait 60 seconds, then plug back in.',
            'Navigate to Settings > System > Software Update and check for updates.',
            'If issues persist, try a factory reset from the System menu.',
          ],
          duration: '5-15 minutes',
          riskLevel: 'Low',
          toolsNeeded: ['TV remote control'],
        ),
        DiyStep(
          title: 'Inspect display and backlight',
          description:
              'Check for visible display issues that may indicate hardware problems.',
          instructions: [
            'In a dark room, turn on the TV and look for uneven backlighting or dark spots.',
            'Display a solid white image to check for dead pixels or color irregularities.',
            'Adjust picture settings (brightness, contrast) to see if the issue improves.',
          ],
          duration: '5-10 minutes',
          riskLevel: 'Low',
          toolsNeeded: ['Dark room', 'USB drive with test images (optional)'],
        ),
      ];
    } else if (assetType.contains('ac') ||
        assetType.contains('air conditioner')) {
      return [
        DiyStep(
          title: 'Clean or replace air filter',
          description:
              'A dirty filter is the most common cause of AC performance issues.',
          instructions: [
            'Open the front panel and carefully remove the air filter.',
            'If reusable, wash the filter with lukewarm water and let it dry completely.',
            'If disposable, replace with the correct size filter.',
          ],
          safetyNote: 'Turn off the AC unit before opening any panels.',
          duration: '10-15 minutes',
          riskLevel: 'Low',
          toolsNeeded: [
            'Soft brush',
            'Mild soap',
            'Replacement filter (if needed)',
          ],
        ),
        DiyStep(
          title: 'Check thermostat and settings',
          description:
              'Incorrect settings or a miscalibrated thermostat can cause cooling problems.',
          instructions: [
            'Set the thermostat to the lowest setting and check if cool air flows.',
            'Ensure the mode is set to "Cool" and not "Fan Only" or "Heat".',
            'Check if the timer or sleep mode is accidentally activated.',
          ],
          duration: '5 minutes',
          riskLevel: 'Low',
          toolsNeeded: ['Remote control'],
        ),
        DiyStep(
          title: 'Inspect outdoor unit and drainage',
          description:
              'Blocked drainage or a dirty outdoor unit can affect cooling performance.',
          instructions: [
            'Check the drain pipe for blockages and clear any visible debris.',
            'Clean the outdoor condenser coils with a garden hose (gentle spray).',
            'Ensure there is at least 2 feet of clearance around the outdoor unit.',
          ],
          duration: '15-20 minutes',
          riskLevel: 'Low',
          toolsNeeded: ['Garden hose', 'Soft brush', 'Cleaning cloth'],
        ),
      ];
    } else if (assetType.contains('microwave')) {
      return [
        DiyStep(
          title: 'Check power and door latch',
          description:
              'Most microwave issues start with power supply or door sensor problems.',
          instructions: [
            'Verify the microwave is plugged in securely and the outlet works.',
            'Check that the door closes firmly and the latch clicks into place.',
            'Try pressing the door release button and re-closing to reset the door switch.',
          ],
          safetyNote:
              'Never attempt to repair internal microwave components — high voltage capacitors can be lethal even when unplugged.',
          duration: '5 minutes',
          riskLevel: 'Low',
          toolsNeeded: ['None required'],
        ),
        DiyStep(
          title: 'Clean interior and turntable',
          description:
              'Food buildup and a misaligned turntable can cause uneven heating and sparking.',
          instructions: [
            'Remove the turntable and its support ring, wash with warm soapy water.',
            'Wipe the interior walls, ceiling, and floor with a damp cloth.',
            'Clean the waveguide cover (small panel on the interior wall) gently.',
          ],
          duration: '10-15 minutes',
          riskLevel: 'Low',
          toolsNeeded: ['Mild dish soap', 'Damp cloth', 'Soft sponge'],
        ),
        DiyStep(
          title: 'Test with a cup of water',
          description:
              'A simple water test can determine if the microwave is heating properly.',
          instructions: [
            'Place 1 cup (8 oz) of room-temperature water in a microwave-safe cup.',
            'Heat on high for exactly 2 minutes.',
            'The water should be very hot to boiling — if lukewarm, the magnetron may be failing.',
          ],
          duration: '5 minutes',
          riskLevel: 'Low',
          toolsNeeded: ['Microwave-safe cup', 'Measuring cup'],
        ),
      ];
    } else {
      // Generic fallback for refrigerators, washers, and unknown types
      return [
        DiyStep(
          title: 'Check power and controls',
          description:
              'Make sure the appliance is receiving power and basic controls are set correctly.',
          instructions: [
            'Verify the plug is firmly inserted and the outlet has power.',
            'Confirm the main power switch or control knob is in the ON position.',
            'Check your home\'s breaker panel for any tripped breakers.',
          ],
          safetyNote:
              'Always turn off power from the main switch before inspecting wiring or connections.',
          duration: '5-10 minutes',
          riskLevel: 'Low',
          toolsNeeded: ['Voltage tester (optional)', 'Flashlight'],
        ),
        DiyStep(
          title: 'Inspect seals and airflow',
          description:
              'Poor sealing or blocked vents can cause performance issues.',
          instructions: [
            'Inspect any door gaskets or seals for cracks, cuts, or gaps.',
            'Make sure vents and openings are not blocked by objects.',
            'Clean any accessible filters or screens.',
          ],
          duration: '5-10 minutes',
          riskLevel: 'Low',
          toolsNeeded: ['Cleaning cloth', 'Flashlight'],
        ),
        DiyStep(
          title: 'Clean filters and components',
          description:
              'Dirty filters and components can significantly reduce efficiency.',
          instructions: [
            'Locate and remove filters according to your appliance manual.',
            'Clean or replace filters as recommended by the manufacturer.',
            'Wipe down accessible surfaces and remove any debris.',
          ],
          duration: '10-15 minutes',
          riskLevel: 'Low',
          toolsNeeded: ['Vacuum cleaner', 'Soft brush', 'Cleaning cloth'],
        ),
      ];
    }
  }

  /// Get fallback parts demo data for the given asset type
  static List<PartOption> getPartsDemoData(
    Map<String, dynamic> asset,
    String assetName,
  ) {
    final assetType =
        (asset['type'] as String?)?.toLowerCase() ?? assetName.toLowerCase();

    if (assetType.contains('refrigerator') || assetType.contains('fridge')) {
      return [
        PartOption(
          name: 'Door gasket seal',
          quantity: 1,
          description: 'Main door rubber seal for better cooling efficiency.',
          priceEncompass: 65,
          priceMarcone: 72,
          priceLocal: 88,
        ),
        PartOption(
          name: 'Thermostat sensor',
          quantity: 1,
          description: 'Temperature sensing probe / assembly.',
          priceEncompass: 42,
          priceMarcone: 48,
          priceLocal: 55,
        ),
        PartOption(
          name: 'Condenser fan motor',
          quantity: 1,
          description: 'OEM condenser fan motor unit.',
          priceEncompass: 95,
          priceMarcone: 102,
          priceLocal: 118,
        ),
      ];
    } else if (assetType.contains('tv') || assetType.contains('television')) {
      return [
        PartOption(
          name: 'LED backlight strip',
          quantity: 1,
          description: 'Replacement LED backlight strip set.',
          priceEncompass: 45,
          priceMarcone: 52,
          priceLocal: 60,
        ),
        PartOption(
          name: 'Power supply board',
          quantity: 1,
          description: 'Main power supply / inverter board.',
          priceEncompass: 78,
          priceMarcone: 85,
          priceLocal: 98,
        ),
        PartOption(
          name: 'HDMI port module',
          quantity: 1,
          description: 'HDMI input connector board assembly.',
          priceEncompass: 35,
          priceMarcone: 42,
          priceLocal: 50,
        ),
      ];
    } else if (assetType.contains('ac') ||
        assetType.contains('air conditioner')) {
      return [
        PartOption(
          name: 'Air filter',
          quantity: 2,
          description: 'Replacement HEPA air filter set.',
          priceEncompass: 28,
          priceMarcone: 35,
          priceLocal: 42,
        ),
        PartOption(
          name: 'Capacitor',
          quantity: 1,
          description: 'Run/start capacitor for compressor motor.',
          priceEncompass: 38,
          priceMarcone: 45,
          priceLocal: 55,
        ),
        PartOption(
          name: 'Thermistor sensor',
          quantity: 1,
          description: 'Room temperature sensing thermistor.',
          priceEncompass: 22,
          priceMarcone: 28,
          priceLocal: 35,
        ),
      ];
    } else if (assetType.contains('microwave')) {
      return [
        PartOption(
          name: 'Turntable motor',
          quantity: 1,
          description: 'Microwave turntable drive motor.',
          priceEncompass: 32,
          priceMarcone: 38,
          priceLocal: 45,
        ),
        PartOption(
          name: 'Door latch assembly',
          quantity: 1,
          description: 'Door switch and latch mechanism kit.',
          priceEncompass: 28,
          priceMarcone: 35,
          priceLocal: 42,
        ),
        PartOption(
          name: 'Waveguide cover',
          quantity: 1,
          description: 'Interior microwave waveguide mica cover.',
          priceEncompass: 12,
          priceMarcone: 15,
          priceLocal: 18,
        ),
      ];
    } else if (assetType.contains('washer') || assetType.contains('washing')) {
      return [
        PartOption(
          name: 'Drain pump',
          quantity: 1,
          description: 'Washer drain pump motor assembly.',
          priceEncompass: 55,
          priceMarcone: 62,
          priceLocal: 72,
        ),
        PartOption(
          name: 'Door boot seal',
          quantity: 1,
          description: 'Front load washer door gasket/boot.',
          priceEncompass: 68,
          priceMarcone: 75,
          priceLocal: 88,
        ),
        PartOption(
          name: 'Water inlet valve',
          quantity: 1,
          description: 'Cold/hot water inlet solenoid valve.',
          priceEncompass: 35,
          priceMarcone: 42,
          priceLocal: 50,
        ),
      ];
    } else {
      return [
        PartOption(
          name: 'Control board',
          quantity: 1,
          description: 'Main electronic control board.',
          priceEncompass: 85,
          priceMarcone: 95,
          priceLocal: 110,
        ),
        PartOption(
          name: 'Power cord',
          quantity: 1,
          description: 'Replacement power supply cord.',
          priceEncompass: 18,
          priceMarcone: 22,
          priceLocal: 28,
        ),
        PartOption(
          name: 'Thermal fuse',
          quantity: 1,
          description: 'Safety thermal cutoff fuse.',
          priceEncompass: 12,
          priceMarcone: 15,
          priceLocal: 20,
        ),
      ];
    }
  }
}
