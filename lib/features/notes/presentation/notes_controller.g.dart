// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allNotesHash() => r'fcf37fcd7a95814ebc63a82cb7c4c5ddcd11630f';

/// See also [allNotes].
@ProviderFor(allNotes)
final allNotesProvider = AutoDisposeStreamProvider<List<Note>>.internal(
  allNotes,
  name: r'allNotesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allNotesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AllNotesRef = AutoDisposeStreamProviderRef<List<Note>>;
String _$notesByParentHash() => r'06150812d9460624c3c80bcb5def5f2a5e053691';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [notesByParent].
@ProviderFor(notesByParent)
const notesByParentProvider = NotesByParentFamily();

/// See also [notesByParent].
class NotesByParentFamily extends Family<AsyncValue<List<Note>>> {
  /// See also [notesByParent].
  const NotesByParentFamily();

  /// See also [notesByParent].
  NotesByParentProvider call(
    int parentType,
    int parentId,
  ) {
    return NotesByParentProvider(
      parentType,
      parentId,
    );
  }

  @override
  NotesByParentProvider getProviderOverride(
    covariant NotesByParentProvider provider,
  ) {
    return call(
      provider.parentType,
      provider.parentId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'notesByParentProvider';
}

/// See also [notesByParent].
class NotesByParentProvider extends AutoDisposeStreamProvider<List<Note>> {
  /// See also [notesByParent].
  NotesByParentProvider(
    int parentType,
    int parentId,
  ) : this._internal(
          (ref) => notesByParent(
            ref as NotesByParentRef,
            parentType,
            parentId,
          ),
          from: notesByParentProvider,
          name: r'notesByParentProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$notesByParentHash,
          dependencies: NotesByParentFamily._dependencies,
          allTransitiveDependencies:
              NotesByParentFamily._allTransitiveDependencies,
          parentType: parentType,
          parentId: parentId,
        );

  NotesByParentProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.parentType,
    required this.parentId,
  }) : super.internal();

  final int parentType;
  final int parentId;

  @override
  Override overrideWith(
    Stream<List<Note>> Function(NotesByParentRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NotesByParentProvider._internal(
        (ref) => create(ref as NotesByParentRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        parentType: parentType,
        parentId: parentId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<Note>> createElement() {
    return _NotesByParentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NotesByParentProvider &&
        other.parentType == parentType &&
        other.parentId == parentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, parentType.hashCode);
    hash = _SystemHash.combine(hash, parentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin NotesByParentRef on AutoDisposeStreamProviderRef<List<Note>> {
  /// The parameter `parentType` of this provider.
  int get parentType;

  /// The parameter `parentId` of this provider.
  int get parentId;
}

class _NotesByParentProviderElement
    extends AutoDisposeStreamProviderElement<List<Note>> with NotesByParentRef {
  _NotesByParentProviderElement(super.provider);

  @override
  int get parentType => (origin as NotesByParentProvider).parentType;
  @override
  int get parentId => (origin as NotesByParentProvider).parentId;
}

String _$notesControllerHash() => r'5bcd3535b886efe6879d51c7c9b8eb3e420b1495';

/// See also [NotesController].
@ProviderFor(NotesController)
final notesControllerProvider =
    AutoDisposeAsyncNotifierProvider<NotesController, void>.internal(
  NotesController.new,
  name: r'notesControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notesControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NotesController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
