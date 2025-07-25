// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'enums.dart';

final class Event {
  final DashEvent eventName;
  late final Map<String, Object?> eventData;

  Event._({required this.eventName, required this.eventData}) {
    if (eventData.containsKey('enabled_features')) {
      throw ArgumentError.value(
        eventData,
        'eventData',
        'The enabled_features key is reserved and cannot '
            "be used as part of an event's data.",
      );
    }
  }

  /// Event that is emitted whenever a user has opted in
  /// or out of the analytics collection.
  ///
  /// [status] - boolean value where `true` indicates user is opting in.
  Event.analyticsCollectionEnabled({required bool status})
      : this._(
            eventName: DashEvent.analyticsCollectionEnabled,
            eventData: {'status': status});

  /// Event that is emitted when an error occurs within
  /// `package:unified_analytics`, tools that are using this package
  /// should not use this event constructor.
  ///
  /// Tools using this package should instead use the more generic
  /// [Event.exception] constructor.
  ///
  /// [workflow] - refers to what process caused the error, such as
  ///   "LogHandler.logFileStats".
  ///
  /// [error] - the name of the error, such as "FormatException".
  ///
  /// [description] - the description of the error being caught.
  Event.analyticsException({
    required String workflow,
    required String error,
    String? description,
  }) : this._(
          eventName: DashEvent.analyticsException,
          eventData: {
            'workflow': workflow,
            'error': error,
            if (description != null) 'description': description,
          },
        );

  /// This is for various workflows within the flutter tool related
  /// to iOS and macOS workflows.
  ///
  /// [workflow] - which workflow is running, such as "assemble".
  ///
  /// [parameter] - subcategory of the workflow, such as "ios-archive".
  ///
  /// [result] - usually to indicate success or failure of the workflow.
  Event.appleUsageEvent({
    required String workflow,
    required String parameter,
    String? result,
  }) : this._(
          eventName: DashEvent.appleUsageEvent,
          eventData: {
            'workflow': workflow,
            'parameter': parameter,
            if (result != null) 'result': result,
          },
        );

  /// Event that is emitted periodically to report the performance of the
  /// analysis server's handling of a specific kind of notification from the
  /// client.
  ///
  /// [duration] - json encoded percentile values indicating how long it took
  ///     from the time the server started handling the notification until the
  ///     server had finished handling the notification.
  ///
  /// [latency] - json encoded percentile values indicating how long it took
  ///     from the time the notification was sent until the server started
  ///     handling it.
  ///
  /// [method] - the name of the notification method that was sent.
  Event.clientNotification({
    required String duration,
    required String latency,
    required String method,
  }) : this._(
          eventName: DashEvent.clientNotification,
          eventData: {
            'duration': duration,
            'latency': latency,
            'method': method,
          },
        );

  /// Event that is emitted periodically to report the performance of the
  /// analysis server's handling of a specific kind of request from the client.
  ///
  /// [duration] - json encoded percentile values indicating how long it took
  ///     from the time the server started handling the request until the server
  ///     had send a response.
  ///
  /// [latency] - json encoded percentile values indicating how long it took
  ///     from the time the request was sent until the server started handling
  ///     it.
  ///
  /// [method] - the name of the request method that was sent.
  ///
  /// If the method is `workspace/didChangeWorkspaceFolders`, then the following
  /// parameters should be included:
  ///
  /// [added] - json encoded percentile values indicating the number of folders
  ///     that were added.
  ///
  /// [removed] - json encoded percentile values indicating the number of
  ///     folders that were removed.
  ///
  /// If the method is `initialized`, then the following parameters should be
  /// included:
  ///
  /// [openWorkspacePaths] - json encoded percentile values indicating the
  ///     number of workspace paths that were opened.
  ///
  /// If the method is `analysis.setAnalysisRoots`, then the following
  /// parameters should be included:
  ///
  /// [included] - json encoded percentile values indicating the number of
  ///     analysis roots in the included list.
  ///
  /// [excluded] - json encoded percentile values indicating the number of
  ///     analysis roots in the excluded list.
  ///
  /// If the method is `analysis.setPriorityFiles`, then the following
  /// parameters should be included:
  ///
  /// [files] - json encoded percentile values indicating the number of priority
  ///     files.
  ///
  Event.clientRequest({
    required String duration,
    required String latency,
    required String method,
    String? added,
    String? excluded,
    String? files,
    String? included,
    String? openWorkspacePaths,
    String? removed,
  }) : this._(
          eventName: DashEvent.clientRequest,
          eventData: {
            if (added != null) 'added': added,
            'duration': duration,
            if (excluded != null) 'excluded': excluded,
            if (files != null) 'files': files,
            if (included != null) 'included': included,
            'latency': latency,
            'method': method,
            if (openWorkspacePaths != null)
              'openWorkspacePaths': openWorkspacePaths,
            if (removed != null) 'removed': removed,
          },
        );

  /// An event that reports when the code size measurement is run
  /// via `--analyze-size`.
  ///
  /// [platform] - string identifier for which platform was run "ios", "apk",
  ///   "aab", etc.
  Event.codeSizeAnalysis({required String platform})
      : this._(
          eventName: DashEvent.codeSizeAnalysis,
          eventData: {
            'platform': platform,
          },
        );

  /// Event that is emitted periodically to report the number of times a given
  /// command has been executed.
  ///
  /// [count] - the number of times the command was executed.
  ///
  /// [name] - the name of the command that was executed.
  Event.commandExecuted({
    required int count,
    required String name,
  }) : this._(
          eventName: DashEvent.commandExecuted,
          eventData: {
            'count': count,
            'name': name,
          },
        );

  /// Event to capture usage values for different flutter commands.
  ///
  /// There are several implementations of the `FlutterCommand` class within the
  /// flutter-tool that pass information based on the [workflow] being ran. An
  /// example of a [workflow] can be "create". The optional parameters for this
  /// constructor are a superset of all the implementations of `FlutterCommand`.
  /// There should never be a time where all of the parameters are passed to
  /// this constructor.
  Event.commandUsageValues({
    required String workflow,
    required bool commandHasTerminal,

    // Assemble && build bundle implementation parameters
    String? buildBundleTargetPlatform,
    bool? buildBundleIsModule,

    // Build aar implementation parameters
    String? buildAarProjectType,
    String? buildAarTargetPlatform,

    // Build apk implementation parameters
    String? buildApkTargetPlatform,
    String? buildApkBuildMode,
    bool? buildApkSplitPerAbi,

    // Build app bundle implementation parameters
    String? buildAppBundleTargetPlatform,
    String? buildAppBundleBuildMode,

    // Create implementation parameters
    String? createProjectType,
    String? createAndroidLanguage,
    String? createIosLanguage,

    // Packages implementation parameters
    int? packagesNumberPlugins,
    bool? packagesProjectModule,
    String? packagesAndroidEmbeddingVersion,

    // Run implementation parameters
    bool? runIsEmulator,
    String? runTargetName,
    String? runTargetOsVersion,
    String? runModeName,
    bool? runProjectModule,
    String? runProjectHostLanguage,
    String? runAndroidEmbeddingVersion,
    bool? runEnableImpeller,
    String? runIOSInterfaceType,
    bool? runIsTest,
  }) : this._(
          eventName: DashEvent.commandUsageValues,
          eventData: {
            'workflow': workflow,
            'commandHasTerminal': commandHasTerminal,
            if (buildBundleTargetPlatform != null)
              'buildBundleTargetPlatform': buildBundleTargetPlatform,
            if (buildBundleIsModule != null)
              'buildBundleIsModule': buildBundleIsModule,
            if (buildAarProjectType != null)
              'buildAarProjectType': buildAarProjectType,
            if (buildAarTargetPlatform != null)
              'buildAarTargetPlatform': buildAarTargetPlatform,
            if (buildApkTargetPlatform != null)
              'buildApkTargetPlatform': buildApkTargetPlatform,
            if (buildApkBuildMode != null)
              'buildApkBuildMode': buildApkBuildMode,
            if (buildApkSplitPerAbi != null)
              'buildApkSplitPerAbi': buildApkSplitPerAbi,
            if (buildAppBundleTargetPlatform != null)
              'buildAppBundleTargetPlatform': buildAppBundleTargetPlatform,
            if (buildAppBundleBuildMode != null)
              'buildAppBundleBuildMode': buildAppBundleBuildMode,
            if (createProjectType != null)
              'createProjectType': createProjectType,
            if (createAndroidLanguage != null)
              'createAndroidLanguage': createAndroidLanguage,
            if (createIosLanguage != null)
              'createIosLanguage': createIosLanguage,
            if (packagesNumberPlugins != null)
              'packagesNumberPlugins': packagesNumberPlugins,
            if (packagesProjectModule != null)
              'packagesProjectModule': packagesProjectModule,
            if (packagesAndroidEmbeddingVersion != null)
              'packagesAndroidEmbeddingVersion':
                  packagesAndroidEmbeddingVersion,
            if (runIsEmulator != null) 'runIsEmulator': runIsEmulator,
            if (runTargetName != null) 'runTargetName': runTargetName,
            if (runTargetOsVersion != null)
              'runTargetOsVersion': runTargetOsVersion,
            if (runModeName != null) 'runModeName': runModeName,
            if (runProjectModule != null) 'runProjectModule': runProjectModule,
            if (runProjectHostLanguage != null)
              'runProjectHostLanguage': runProjectHostLanguage,
            if (runAndroidEmbeddingVersion != null)
              'runAndroidEmbeddingVersion': runAndroidEmbeddingVersion,
            if (runEnableImpeller != null)
              'runEnableImpeller': runEnableImpeller,
            if (runIOSInterfaceType != null)
              'runIOSInterfaceType': runIOSInterfaceType,
            if (runIsTest != null) 'runIsTest': runIsTest,
          },
        );

  /// Event that is emitted on shutdown to report the structure of the analysis
  /// contexts created immediately after startup.
  ///
  /// [immediateFileCount] - the number of files in one of the analysis
  ///     contexts.
  ///
  /// [immediateFileLineCount] - the number of lines in the immediate files.
  ///
  /// [numberOfContexts] - the number of analysis context created.
  ///
  /// [transitiveFileCount] - the number of files reachable from the files in
  ///     each analysis context, where files can be counted multiple times if
  ///     they are reachable from multiple contexts.
  ///
  /// [transitiveFileLineCount] - the number of lines in the transitive files,
  ///     where files can be counted multiple times if they are reachable from
  ///     multiple contexts.
  ///
  /// [transitiveFileUniqueCount] - the number of unique files reachable from
  ///     the files in each analysis context.
  ///
  /// [transitiveFileUniqueLineCount] - the number of lines in the unique
  ///     transitive files.
  ///
  /// [libraryCycleLibraryCounts] - json encoded percentile values indicating
  ///     the number of libraries in a single library cycle.
  ///
  /// [libraryCycleLineCounts] - json encoded percentile values indicating the
  ///     number of lines of code in all of the files in a single library cycle.
  ///
  /// [contextsFromBothFiles] - the number of contexts that were created because
  ///     of both a package config and an analysis options file.
  ///
  /// [contextsFromOptionsFiles] - the number of contexts that were created
  ///     because of an analysis options file.
  ///
  /// [contextsFromPackagesFiles] - the number of contexts that were created
  ///     because of a package config file.
  ///
  /// [contextsWithoutFiles] - the number of contexts that were created because
  ///     of the lack of either a package config or an analysis options file.
  Event.contextStructure({
    required int immediateFileCount,
    required int immediateFileLineCount,
    required int numberOfContexts,
    required int transitiveFileCount,
    required int transitiveFileLineCount,
    required int transitiveFileUniqueCount,
    required int transitiveFileUniqueLineCount,
    String libraryCycleLibraryCounts = '',
    String libraryCycleLineCounts = '',
    int contextsFromBothFiles = 0,
    int contextsFromOptionsFiles = 0,
    int contextsFromPackagesFiles = 0,
    int contextsWithoutFiles = 0,
  }) : this._(
          eventName: DashEvent.contextStructure,
          eventData: {
            'immediateFileCount': immediateFileCount,
            'immediateFileLineCount': immediateFileLineCount,
            'numberOfContexts': numberOfContexts,
            'transitiveFileCount': transitiveFileCount,
            'transitiveFileLineCount': transitiveFileLineCount,
            'transitiveFileUniqueCount': transitiveFileUniqueCount,
            'transitiveFileUniqueLineCount': transitiveFileUniqueLineCount,
            'libraryCycleLibraryCounts': libraryCycleLibraryCounts,
            'libraryCycleLineCounts': libraryCycleLineCounts,
            'contextsFromBothFiles': contextsFromBothFiles,
            'contextsFromOptionsFiles': contextsFromOptionsFiles,
            'contextsFromPackagesFiles': contextsFromPackagesFiles,
            'contextsWithoutFiles': contextsWithoutFiles,
          },
        );

  /// Event that is emitted when a Dart CLI command has been executed.
  ///
  /// [name] - the name of the command that was executed
  ///
  /// [enabledExperiments] - a set of Dart language experiments enabled when
  ///          running the command.
  ///
  /// [exitCode] - the process exit code set as a result of running the command.
  Event.dartCliCommandExecuted({
    required String name,
    required String enabledExperiments,
    int? exitCode,
  }) : this._(
          eventName: DashEvent.dartCliCommandExecuted,
          eventData: {
            'name': name,
            'enabledExperiments': enabledExperiments,
            if (exitCode != null) 'exitCode': exitCode,
          },
        );

  /// Event that is sent from DevTools for various different actions as
  /// indicated by the [eventCategory].
  ///
  /// The optional parameters in the parameter list contain metadata that is
  /// sent with each event, when available.
  ///
  /// [additionalMetrics] may contain any additional data for the event being
  /// sent. This often looks like metrics that are unique to the event or to a
  /// specific screen.
  Event.devtoolsEvent({
    required String screen,
    required String eventCategory,
    required String label,
    required int value,

    // Defaulted values
    bool userInitiatedInteraction = true,

    // Optional parameters
    String? g3Username,
    String? userApp,
    String? userBuild,
    String? userPlatform,
    String? devtoolsPlatform,
    String? devtoolsChrome,
    String? devtoolsVersion,
    String? ideLaunched,
    String? isExternalBuild,
    String? isEmbedded,
    String? ideLaunchedFeature,
    String? isWasm,
    CustomMetrics? additionalMetrics,
  }) : this._(
          eventName: DashEvent.devtoolsEvent,
          eventData: {
            'screen': screen,
            'eventCategory': eventCategory,
            'label': label,
            'value': value,

            'userInitiatedInteraction': userInitiatedInteraction,

            // Optional parameters
            if (g3Username != null) 'g3Username': g3Username,
            if (userApp != null) 'userApp': userApp,
            if (userBuild != null) 'userBuild': userBuild,
            if (userPlatform != null) 'userPlatform': userPlatform,
            if (devtoolsPlatform != null) 'devtoolsPlatform': devtoolsPlatform,
            if (devtoolsChrome != null) 'devtoolsChrome': devtoolsChrome,
            if (devtoolsVersion != null) 'devtoolsVersion': devtoolsVersion,
            if (ideLaunched != null) 'ideLaunched': ideLaunched,
            if (isExternalBuild != null) 'isExternalBuild': isExternalBuild,
            if (isEmbedded != null) 'isEmbedded': isEmbedded,
            if (ideLaunchedFeature != null)
              'ideLaunchedFeature': ideLaunchedFeature,
            if (isWasm != null) 'isWasm': isWasm,
            if (additionalMetrics != null) ...additionalMetrics.toMap(),
          },
        );

  /// Event that contains the results for a specific doctor validator.
  ///
  /// [validatorName] - the name for the doctor validator.
  ///
  /// [result] - the final result for a specific doctor validator.
  ///
  /// [partOfGroupedValidator] - `true` indicates that this validator belongs
  ///   to a grouped validator.
  ///
  /// [doctorInvocationId] - epoch formatted timestamp that can be used in
  ///   combination with the client ID in GA4 to group the validators that
  ///   ran in one doctor invocation.
  ///
  /// [statusInfo] - optional description of the result from the
  ///   doctor validator.
  Event.doctorValidatorResult({
    required String validatorName,
    required String result,
    required bool partOfGroupedValidator,
    required int doctorInvocationId,
    String? statusInfo,
  }) : this._(
          eventName: DashEvent.doctorValidatorResult,
          eventData: {
            'validatorName': validatorName,
            'result': result,
            'partOfGroupedValidator': partOfGroupedValidator,
            'doctorInvocationId': doctorInvocationId,
            if (statusInfo != null) 'statusInfo': statusInfo,
          },
        );

  /// Generic event for all dash tools to use when encountering an
  /// exception that we want to log.
  ///
  /// [exception] - string representation of the exception that occured.
  /// [data] - optional structured data to include with the exception event.
  Event.exception({
    required String exception,
    Map<String, Object?> data = const <String, Object?>{},
  }) : this._(
          eventName: DashEvent.exception,
          eventData: {
            'exception': exception,
            ...Map.from(data)..removeWhere((key, value) => value == null),
          },
        );

  /// Event that is emitted from the flutter tool when a build invocation
  /// has been run by the user.
  ///
  /// [label] - the identifier for that build event.
  ///
  /// [buildType] - the identifier for which platform the build event was for,
  ///   examples include "ios", "gradle", and "web".
  ///
  /// [command] - the command that was ran to kick off the build event.
  ///
  /// [settings] - the settings used for the build event related to
  ///   configuration and other relevant build information.
  ///
  /// [error] - short identifier used to explain the cause of the build error,
  ///   stacktraces should not be passed to this parameter.
  Event.flutterBuildInfo({
    required String label,
    required String buildType,
    String? command,
    String? settings,
    String? error,
  }) : this._(
          eventName: DashEvent.flutterBuildInfo,
          eventData: {
            'label': label,
            'buildType': buildType,
            if (command != null) 'command': command,
            if (settings != null) 'settings': settings,
            if (error != null) 'error': error,
          },
        );

  /// Provides information about which flutter command was run
  /// and whether it was successful.
  ///
  /// [commandPath] - information about the flutter command, such as "build/apk".
  ///
  /// [result] - if the command failed or succeeded.
  ///
  /// [commandHasTerminal] - boolean indicating if the flutter command ran with
  ///   a terminal.
  ///
  /// [maxRss] - maximum resident size for a given flutter command.
  Event.flutterCommandResult({
    required String commandPath,
    required String result,
    required bool commandHasTerminal,
    int? maxRss,
  }) : this._(
          eventName: DashEvent.flutterCommandResult,
          eventData: {
            'commandPath': commandPath,
            'result': result,
            'commandHasTerminal': commandHasTerminal,
            if (maxRss != null) 'maxRss': maxRss,
          },
        );

  Event.flutterWasmDryRun({
    required String result,
    required int exitCode,
    String? findingsSummary,
  }) : this._(
          eventName: DashEvent.flutterWasmDryRun,
          eventData: {
            'result': result,
            'exitCode': exitCode,
            if (findingsSummary != null) 'findings': findingsSummary,
          },
        );

  /// Provides information about the plugins injected into an iOS or macOS
  /// project.
  ///
  /// This event is not sent if a project has no plugins.
  ///
  /// [platform] - The project's platform. Either 'ios' or 'macos'.
  ///
  /// [isModule] - whether the project is an add-to-app Flutter module.
  ///
  /// [swiftPackageManagerUsable] - if `true`, Swift Package Manager can be used
  /// for the project's plugins if any are Swift Package Manager compatible.
  ///
  /// [swiftPackageManagerFeatureEnabled] - if the Swift Package Manager feature
  /// flag is on. If false, Swift Package Manager is off for all projects on
  /// the development machine.
  ///
  /// [projectDisabledSwiftPackageManager] - if the project's .pubspec has
  /// `disable-swift-package-manager: true`. This turns off Swift Package
  /// Manager for a single project.
  ///
  /// [projectHasSwiftPackageManagerIntegration] - if the Xcode project has
  /// Swift Package Manager integration. If `false`, the project needs to be
  /// migrated.
  ///
  /// [pluginCount] - the total number of plugins for this project. A plugin
  /// can be compatible with both Swift Package Manager and CocoaPods. Plugins
  /// compatible with both will be counted in both [swiftPackageCount] and
  /// [podCount]. Swift Package Manager was used to inject all plugins if
  /// [pluginCount] is equal to [swiftPackageCount].
  ///
  /// [swiftPackageCount] - the number of plugins compatible with Swift Package
  /// Manager. This is less than or equal to [pluginCount]. If
  /// [swiftPackageCount] is less than [pluginCount], the project uses CocoaPods
  /// to inject plugins.
  ///
  /// [podCount] - the number of plugins compatible with CocoaPods. This is less
  /// than or equal to [podCount].
  Event.flutterInjectDarwinPlugins({
    required String platform,
    required bool isModule,
    required bool swiftPackageManagerUsable,
    required bool swiftPackageManagerFeatureEnabled,
    required bool projectDisabledSwiftPackageManager,
    required bool projectHasSwiftPackageManagerIntegration,
    required int pluginCount,
    required int swiftPackageCount,
    required int podCount,
  }) : this._(
          eventName: DashEvent.flutterInjectDarwinPlugins,
          eventData: {
            'platform': platform,
            'isModule': isModule,
            'swiftPackageManagerUsable': swiftPackageManagerUsable,
            'swiftPackageManagerFeatureEnabled':
                swiftPackageManagerFeatureEnabled,
            'projectDisabledSwiftPackageManager':
                projectDisabledSwiftPackageManager,
            'projectHasSwiftPackageManagerIntegration':
                projectHasSwiftPackageManagerIntegration,
            'pluginCount': pluginCount,
            'swiftPackageCount': swiftPackageCount,
            'podCount': podCount,
          },
        );

  // TODO: eliasyishak, remove this or replace once we have a generic
  //  timing event that can be used by potentially more than one DashTool
  Event.hotReloadTime({required int timeMs})
      : this._(
          eventName: DashEvent.hotReloadTime,
          eventData: {'timeMs': timeMs},
        );

  /// Events to be sent for the Flutter Hot Runner.
  Event.hotRunnerInfo({
    required String label,
    required String targetPlatform,
    required String sdkName,
    required bool emulator,
    required bool fullRestart,
    String? reason,
    int? finalLibraryCount,
    int? syncedLibraryCount,
    int? syncedClassesCount,
    int? syncedProceduresCount,
    int? syncedBytes,
    int? invalidatedSourcesCount,
    int? transferTimeInMs,
    int? overallTimeInMs,
    int? compileTimeInMs,
    int? findInvalidatedTimeInMs,
    int? scannedSourcesCount,
    int? reassembleTimeInMs,
    int? reloadVMTimeInMs,
  }) : this._(
          eventName: DashEvent.hotRunnerInfo,
          eventData: {
            'label': label,
            'targetPlatform': targetPlatform,
            'sdkName': sdkName,
            'emulator': emulator,
            'fullRestart': fullRestart,
            if (reason != null) 'reason': reason,
            if (finalLibraryCount != null)
              'finalLibraryCount': finalLibraryCount,
            if (syncedLibraryCount != null)
              'syncedLibraryCount': syncedLibraryCount,
            if (syncedClassesCount != null)
              'syncedClassesCount': syncedClassesCount,
            if (syncedProceduresCount != null)
              'syncedProceduresCount': syncedProceduresCount,
            if (syncedBytes != null) 'syncedBytes': syncedBytes,
            if (invalidatedSourcesCount != null)
              'invalidatedSourcesCount': invalidatedSourcesCount,
            if (transferTimeInMs != null) 'transferTimeInMs': transferTimeInMs,
            if (overallTimeInMs != null) 'overallTimeInMs': overallTimeInMs,
            if (compileTimeInMs != null) 'compileTimeInMs': compileTimeInMs,
            if (findInvalidatedTimeInMs != null)
              'findInvalidatedTimeInMs': findInvalidatedTimeInMs,
            if (scannedSourcesCount != null)
              'scannedSourcesCount': scannedSourcesCount,
            if (reassembleTimeInMs != null)
              'reassembleTimeInMs': reassembleTimeInMs,
            if (reloadVMTimeInMs != null) 'reloadVMTimeInMs': reloadVMTimeInMs,
          },
        );

  /// Event that is emitted periodically to report the number of times each lint
  /// has been enabled.
  ///
  /// [count] - the number of options files in which the lint was enabled.
  ///
  /// [name] - the name of the lint.
  Event.lintUsageCount({
    required int count,
    required String name,
  }) : this._(
          eventName: DashEvent.lintUsageCount,
          eventData: {
            'count': count,
            'name': name,
          },
        );

  /// Event that is emitted periodically to report the amount of memory being
  /// used.
  ///
  /// [rss] - the resident set size in megabytes.
  ///
  /// If this is not the first time memory has been reported for this session,
  /// then the following parameters should be included:
  ///
  /// [periodSec] - the number of seconds since the last memory usage data was
  ///     gathered.
  ///
  /// [mbPerSec] - the number of megabytes of memory that were added or
  ///     subtracted per second since the last report.
  Event.memoryInfo({
    required int rss,
    int? periodSec,
    double? mbPerSec,
  }) : this._(
          eventName: DashEvent.memoryInfo,
          eventData: {
            'rss': rss,
            if (periodSec != null) 'periodSec': periodSec,
            if (mbPerSec != null) 'mbPerSec': mbPerSec
          },
        );

  /// Event that is emitted periodically to report the performance of plugins
  /// when handling requests.
  ///
  /// [duration] - json encoded percentile values indicating how long it took
  ///     from the time the request was sent to the plugin until the response
  ///     was processed by the server.
  ///
  /// [method] - the name of the request sent to the plugin.
  ///
  /// [pluginId] - the id of the plugin whose performance is being reported.
  Event.pluginRequest({
    required String duration,
    required String method,
    required String pluginId,
  }) : this._(
          eventName: DashEvent.pluginRequest,
          eventData: {
            'duration': duration,
            'method': method,
            'pluginId': pluginId,
          },
        );

  /// Event that is emitted periodically to report the frequency with which a
  /// given plugin has been used.
  ///
  /// [count] - the number of times plugins usage was changed, which will always
  ///     be at least one.
  ///
  /// [enabled] - json encoded percentile values indicating the number of
  ///     contexts for which the plugin was enabled.
  ///
  /// [pluginId] - the id of the plugin associated with the data.
  Event.pluginUse({
    required int count,
    required String enabled,
    required String pluginId,
  }) : this._(
          eventName: DashEvent.pluginUse,
          eventData: {
            'count': count,
            'enabled': enabled,
            'pluginId': pluginId,
          },
        );

  /// Event that is emitted when `pub get` is run.
  ///
  /// [packageName] - the name of the package that was resolved
  ///
  /// [version] - the resolved, canonicalized package version
  ///
  /// [dependencyType] - the kind of dependency that resulted in this package
  ///     being resolved (e.g., direct, transitive, or dev dependencies).
  Event.pubGet({
    required String packageName,
    required String version,
    required String dependencyType,
  }) : this._(
          eventName: DashEvent.pubGet,
          eventData: {
            'packageName': packageName,
            'version': version,
            'dependencyType': dependencyType,
          },
        );

  /// Event that is emitted on shutdown to report information about the whole
  /// session for which the analysis server was running.
  ///
  /// [clientId] - the id of the client that started the server.
  ///
  /// [clientVersion] - the version of the client that started the server.
  ///
  /// [duration] - the number of milliseconds for which the server was running.
  ///
  /// [flags] - the flags passed to the analysis server on startup, without any
  ///     argument values for flags that take values, or an empty string if
  ///     there were no arguments.
  ///
  /// [parameters] - the names of the parameters passed to the `initialize`
  ///     request, or an empty string if the `initialize` request was not sent
  ///     or if there were no parameters given.
  Event.serverSession({
    required String clientId,
    required String clientVersion,
    required int duration,
    required String flags,
    required String parameters,
  }) : this._(
          eventName: DashEvent.serverSession,
          eventData: {
            'clientId': clientId,
            'clientVersion': clientVersion,
            'duration': duration,
            'flags': flags,
            'parameters': parameters,
          },
        );

  /// Event that is emitted periodically to report the number of times the
  /// severity of a diagnostic was changed in the analysis options file.
  ///
  /// [diagnostic] - the name of the diagnostic whose severity was changed.
  ///
  /// [adjustments] - json encoded map of severities to the number of times the
  ///     diagnostic's severity was changed to the key.
  Event.severityAdjustment({
    required String diagnostic,
    required String adjustments,
  }) : this._(
          eventName: DashEvent.severityAdjustment,
          eventData: {
            'diagnostic': diagnostic,
            'adjustments': adjustments,
          },
        );

  /// Event that is emitted by `package:unified_analytics` when
  /// the user takes action when prompted with a survey.
  ///
  /// [surveyId] - the unique id for a given survey.
  ///
  /// [status] - the string identifier for a given `SurveyButton` under the
  ///     `action` field.
  Event.surveyAction({
    required String surveyId,
    required String status,
  }) : this._(
          eventName: DashEvent.surveyAction,
          eventData: {
            'surveyId': surveyId,
            'status': status,
          },
        );

  /// Event that is emitted by `package:unified_analytics` when the
  /// user has been shown a survey.
  ///
  /// [surveyId] - the unique id for a given survey.
  Event.surveyShown({
    required String surveyId,
  }) : this._(
          eventName: DashEvent.surveyShown,
          eventData: {
            'surveyId': surveyId,
          },
        );

  /// Event that records how long a given process takes to complete.
  ///
  /// [workflow] - the overall process or command being run, for example
  ///   "build" is a possible value for the flutter tool.
  ///
  /// [variableName] - the specific variable being measured, for example
  ///   "gradle" would indicate how long it took for a gradle build under the
  ///   "build" [workflow].
  ///
  /// [elapsedMilliseconds] - how long the process took in milliseconds.
  ///
  /// [label] - an optional field that can be used for further filtering, for
  ///   example, "success" can indicate how long a successful build in gradle
  ///   takes to complete.
  Event.timing({
    required String workflow,
    required String variableName,
    required int elapsedMilliseconds,
    String? label,
  }) : this._(
          eventName: DashEvent.timing,
          eventData: {
            'workflow': workflow,
            'variableName': variableName,
            'elapsedMilliseconds': elapsedMilliseconds,
            if (label != null) 'label': label,
          },
        );

  /// An event that is sent from the Dart MCP server.
  ///
  /// The [client] is the name of the client, as given when it connected to the
  /// MCP server, and [clientVersion] is the version of the client.
  ///
  /// The [serverVersion] is the version of the Dart MCP server.
  ///
  /// The [type] identifies the kind of event this is, and [additionalData] is
  /// the actual data for the event.
  Event.dartMCPEvent({
    required String client,
    required String clientVersion,
    required String serverVersion,
    required String type,
    CustomMetrics? additionalData,
  }) : this._(
          eventName: DashEvent.dartMCPEvent,
          eventData: {
            'client': client,
            'clientVersion': clientVersion,
            'serverVersion': serverVersion,
            'type': type,
            ...?additionalData?.toMap(),
          },
        );

  @override
  int get hashCode => Object.hash(eventName, jsonEncode(eventData));

  @override
  bool operator ==(Object other) =>
      other is Event &&
      other.runtimeType == runtimeType &&
      other.eventName == eventName &&
      _compareEventData(other.eventData, eventData);

  /// Converts an instance of [Event] to JSON.
  String toJson() => jsonEncode({
        'eventName': eventName.label,
        'eventData': eventData,
      });

  @override
  String toString() => toJson();

  /// Utility function to take in two maps [a] and [b] and compares them
  /// to ensure that they have the same keys and values
  bool _compareEventData(Map<String, Object?> a, Map<String, Object?> b) {
    final keySetA = a.keys.toSet();
    final keySetB = b.keys.toSet();
    final intersection = keySetA.intersection(keySetB);

    // Ensure that the keys are the same for each object
    if (intersection.length != keySetA.length ||
        intersection.length != keySetB.length) {
      return false;
    }

    // Ensure that each of the key's values are the same
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }

    return true;
  }

  /// Returns a valid instance of [Event] if [json] follows the correct schema.
  ///
  /// Common use case for this static method involves clients of this package
  /// that have a client-server setup where the server sends events that the
  /// client creates.
  static Event? fromJson(String json) {
    try {
      final jsonMap = jsonDecode(json) as Map<String, Object?>;

      // Ensure that eventName is a string and a valid label and
      // eventData is a nested object
      if (jsonMap
          case {
            'eventName': final String eventName,
            'eventData': final Map<String, Object?> eventData,
          }) {
        final dashEvent = DashEvent.fromLabel(eventName);
        if (dashEvent == null) return null;

        return Event._(
          eventName: dashEvent,
          eventData: eventData,
        );
      }

      return null;
    } on FormatException {
      return null;
    }
  }
}

/// A base class for custom metrics that will be defined by a unified_analytics
/// client.
///
/// This base type can be used as a parameter in any event constructor that
/// allows custom metrics to be added by a unified_analytics client.
abstract base class CustomMetrics {
  /// Converts the custom metrics data to a [Map] object.
  ///
  /// This must be a JSON encodable [Map].
  Map<String, Object> toMap();
}
