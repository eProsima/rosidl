@# Included from rosidl_generator_c/resource/idl__struct.h.em
@{
from rosidl_parser.definition import AbstractGenericString
from rosidl_parser.definition import AbstractNestedType
from rosidl_parser.definition import AbstractSequence
from rosidl_parser.definition import AbstractString
from rosidl_parser.definition import AbstractWString
from rosidl_parser.definition import BasicType
from rosidl_parser.definition import BOOLEAN_TYPE
from rosidl_parser.definition import BoundedSequence
from rosidl_parser.definition import CHARACTER_TYPES
from rosidl_parser.definition import FLOATING_POINT_TYPES
from rosidl_parser.definition import INTEGER_TYPES
from rosidl_parser.definition import NamespacedType
from rosidl_parser.definition import OCTET_TYPE
from rosidl_parser.definition import SERVICE_REQUEST_MESSAGE_SUFFIX
from rosidl_parser.definition import SERVICE_RESPONSE_MESSAGE_SUFFIX
from rosidl_generator_c import basetype_to_c
from rosidl_generator_c import idl_declaration_to_c
from rosidl_generator_c import idl_structure_type_sequence_to_c_typename
from rosidl_generator_c import idl_structure_type_to_c_include_prefix
from rosidl_generator_c import idl_structure_type_to_c_typename
from rosidl_generator_c import interface_path_to_string
from rosidl_generator_c import type_hash_to_c_definition
from rosidl_generator_c import value_to_c
from rosidl_generator_type_description import RAW_SOURCE_VAR
from rosidl_generator_type_description import TYPE_DESCRIPTION_VAR
from rosidl_generator_type_description import TYPE_HASH_VAR
}@
@#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
@# Collect necessary include directives for all members
@{
from collections import OrderedDict
message_typename = idl_structure_type_to_c_typename(message.structure.namespaced_type)
includes = OrderedDict()
for member in message.structure.members:
    if isinstance(member.type, AbstractSequence) and isinstance(member.type.value_type, BasicType):
        member_names = includes.setdefault(
            'rosidl_runtime_c/primitives_sequence.h', [])
        member_names.append(member.name)
        continue
    type_ = member.type
    if isinstance(type_, AbstractNestedType):
        type_ = type_.value_type
    if isinstance(type_, AbstractString):
        member_names = includes.setdefault('rosidl_runtime_c/string.h', [])
        member_names.append(member.name)
    elif isinstance(type_, AbstractWString):
        member_names = includes.setdefault(
            'rosidl_runtime_c/u16string.h', [])
        member_names.append(member.name)
    elif isinstance(type_, NamespacedType):
        if (
            message.structure.namespaced_type.namespaces[-1] in ['action', 'srv'] and (
            type_.name.endswith(SERVICE_REQUEST_MESSAGE_SUFFIX) or
            type_.name.endswith(SERVICE_RESPONSE_MESSAGE_SUFFIX))
        ):
            typename = type_.name.rsplit('_', 1)[0]
            if typename == message.structure.namespaced_type.name.rsplit('_', 1)[0]:
                continue
        include_prefix = idl_structure_type_to_c_include_prefix(
            type_, 'detail')
        member_names = includes.setdefault(
            include_prefix + '__struct.h', [])
        member_names.append(member.name)
}@
@#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

@#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
// Type Hash for interface
static const rosidl_type_hash_t @(message_typename)__@(TYPE_HASH_VAR) = @(type_hash_to_c_definition(type_hash['message']));

/// Type Description for interface
ROSIDL_GENERATOR_C_PUBLIC_@(package_name)
extern const rosidl_runtime_c__type_description__TypeDescription @(message_typename)__@(TYPE_DESCRIPTION_VAR);

/// Raw sources defining the type description
ROSIDL_GENERATOR_C_PUBLIC_@(package_name)
extern const rosidl_runtime_c__type_description__TypeSource__Sequence @(message_typename)__@(RAW_SOURCE_VAR);

// Constants defined in the message
@[for constant in message.constants]@

/// Constant '@(constant.name)'.
@{comments = constant.get_comment_lines()}@
@[if comments]@
/**
@[  for line in comments]@
@[    if line]@
  * @(line)
@[    else]@
  *
@[    end if]@
@[  end for]@
 */
@[end if]@
@[    if isinstance(constant.type, BasicType)]@
@[        if constant.type.typename in (
                *INTEGER_TYPES, *CHARACTER_TYPES, OCTET_TYPE
        )]@
enum
{
  @(message_typename)__@(constant.name) = @(value_to_c(constant.type, constant.value))
};
@[        elif constant.type.typename in (*FLOATING_POINT_TYPES, BOOLEAN_TYPE)]@
static const @(basetype_to_c(constant.type)) @(message_typename)__@(constant.name) = @(value_to_c(constant.type, constant.value));
@[        else]@
@{assert False, 'Unhandled basic type: ' + str(constant.type)}@
@[        end if]@
@[    elif isinstance(constant.type, AbstractString)]@
static const char * const @(message_typename)__@(constant.name) = @(value_to_c(constant.type, constant.value));
@[    end if]@
@[end for]@
@#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
@
@#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
@[if includes]@

// Include directives for member types
@[    for header_file, member_names in includes.items()]@
@[        for member_name in member_names]@
// Member '@(member_name)'
@[        end for]@
@[        if header_file in include_directives]@
// already included above
// @
@[        else]@
@{include_directives.add(header_file)}@
@[        end if]@
#include "@(header_file)"
@[    end for]@
@[end if]@
@#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
@
@#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
@# Constants for array and string fields with an upper bound
@{
upper_bounds = []
for member in message.structure.members:
    type_ = member.type
    if isinstance(type_, BoundedSequence):
        upper_bounds.append((
            member.name,
            '%s__%s__MAX_SIZE' % (message_typename, member.name),
            type_.maximum_size,
        ))
    if isinstance(type_, AbstractNestedType):
        type_ = type_.value_type
    if isinstance(type_, AbstractGenericString) and type_.has_maximum_size():
        upper_bounds.append((
            member.name,
            '%s__%s__MAX_STRING_SIZE' % (message_typename, member.name),
            type_.maximum_size,
        ))
}@
@[if upper_bounds]@

// constants for array fields with an upper bound
@[  for field_name, enum_name, enum_value in upper_bounds]@
// @(field_name)
enum
{
  @(enum_name) = @(enum_value)
};
@[  end for]@
@[end if]@
@#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

@#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
/// Struct defined in @(interface_path_to_string(interface_path)) in the package @(package_name).
@{comments = message.structure.get_comment_lines()}@
@[if comments]@
/**
@[  for line in comments]@
@[    if line]@
  * @(line)
@[    else]@
  *
@[    end if]@
@[  end for]@
 */
@[end if]@
typedef struct @(message_typename)
{
@[for member in message.structure.members]@
@[  for line in member.get_comment_lines()]@
@[    if line]@
  /// @(line)
@[    else]@
  ///
@[    end if]@
@[  end for]@
  @(idl_declaration_to_c(member.type, member.name));
@[end for]@
} @(message_typename);
@#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

@#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
// Struct for a sequence of @(message_typename).
typedef struct @(idl_structure_type_sequence_to_c_typename(message.structure.namespaced_type))
{
  @(message_typename) * data;
  /// The number of valid items in data
  size_t size;
  /// The number of allocated items in data
  size_t capacity;
} @(idl_structure_type_sequence_to_c_typename(message.structure.namespaced_type));
