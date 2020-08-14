# SPDX-FileCopyrightText: 2020 AlgorIT Software Consultancy <https://github.com/algoritnl>
# SPDX-License-Identifier: CC0-1.0

include_guard(GLOBAL)

#[=======================================================================[.rst:
multiple_choice
---------------

Validates and configures a cache variable against a specific list of allowed
values. For scalar variables, it generates a dropdown selection menu in the
CMake GUI. For list-based modes, it validates that all elements are part of
the allowed values.

.. code-block:: cmake

  multiple_choice(
    <var>
    VALID_VALUES <val1> [<val2> ...]
    [DEFAULT <default_val> [<default_val2> ...]]
    [VALUE_MODE SINGLE|MULTI|SEQUENCE]
    [TYPE <type>]
    [HELP <help_string>]
    [DEFAULT_ON_ERROR]
    [FATAL_ERROR]
  )

Required Arguments:
  ``<var>``
    The name of the CMake variable to be configured and validated.

  ``VALID_VALUES``
    A list of all valid strings allowed for this variable. The list must not
    contain duplicate entries or empty string entries.

Optional Arguments:
  ``VALUE_MODE``
    Controls how the variable is interpreted:

    * ``SINGLE`` (default): The variable must contain exactly one value.
    * ``MULTI``: The variable is an **ordered list** of **unique** values. Duplicates are invalid.
    * ``SEQUENCE``: The variable is an **ordered list** of values. Duplicates are allowed.

  ``DEFAULT``
    The default value or an **ordered list** of values. Must be a subset of ``VALID_VALUES``.

    If DEFAULT is omitted, the following defaults are applied based on ``VALUE_MODE``:
    * ``SINGLE``: the first entry in ``VALID_VALUES``.
    * ``MULTI``: an empty list.
    * ``SEQUENCE``: an empty list.

  ``TYPE``
    The CMake cache variable type (e.g., ``STRING``, ``PATH``). Defaults to ``STRING``.

  ``HELP``
    The descriptive help string displayed in the CMake GUI or cache.

  ``DEFAULT_ON_ERROR``
    If the user input is invalid, a warning is emitted and the variable is
    reset to the ``DEFAULT`` value.

  ``FATAL_ERROR``
    If the user input is invalid, stops CMake immediately with a fatal error.

.. note::
  ``DEFAULT_ON_ERROR`` and ``FATAL_ERROR`` are mutually exclusive.

.. note::
  Only ``VALUE_MODE=SINGLE`` produces a GUI dropdown list via the ``STRINGS`` cache property.

.. note::
  Values must be single tokens without spaces or semicolons.
  CMake list semantics do not support multi‑word values in this function.

.. note::
   This function supports a wide compatibility range from CMake 3.16 up to 4.3+.
#]=======================================================================]
function(multiple_choice MC_VAR)
    list(APPEND CMAKE_MESSAGE_CONTEXT multiple_choice)

    # ------------------------------------------------------------
    #  1. PARAMETER PARSING
    # ------------------------------------------------------------
    set(_mc_option_keywords DEFAULT_ON_ERROR FATAL_ERROR)
    set(_mc_single_value_keywords VALUE_MODE TYPE HELP)
    set(_mc_multi_value_keywords VALID_VALUES DEFAULT)

    cmake_parse_arguments(PARSE_ARGV 1 MC "${_mc_option_keywords}" "${_mc_single_value_keywords}" "${_mc_multi_value_keywords}")

    # ------------------------------------------------------------
    #  2. PARAMETER VALIDATION
    # ------------------------------------------------------------
    message(TRACE "[MCT200:${MC_VAR}] PARAMETER VALIDATION")

    # 2.1. VALID_VALUES validation
    # 2.1.1. Ensure VALID_VALUES is provided
    if(NOT DEFINED MC_VALID_VALUES)
        message(FATAL_ERROR "[MCE211:${MC_VAR}] VALID_VALUES is a required argument.")
    endif()

    # 2.1.2. At least one valid value must be provided
    list(LENGTH MC_VALID_VALUES _mc_valid_values_len)
    if(_mc_valid_values_len EQUAL 0)
        message(FATAL_ERROR "[MCE212:${MC_VAR}] VALID_VALUES requires at least one entry.")
    endif()

    # 2.1.3. Check for empty string entries inside VALID_VALUES
    if("" IN_LIST MC_VALID_VALUES)
        message(FATAL_ERROR "[MCE213:${MC_VAR}] VALID_VALUES contains empty string entries.")
    endif()

    # 2.1.4. Check for duplicate values
    set(_mc_temp_list ${MC_VALID_VALUES})
    list(REMOVE_DUPLICATES _mc_temp_list)
    list(LENGTH _mc_temp_list _mc_temp_list_len)
    if(NOT _mc_valid_values_len EQUAL _mc_temp_list_len)
        message(FATAL_ERROR "[MCE214:${MC_VAR}] VALID_VALUES contains duplicate entries.")
    endif()

    message(DEBUG "[MCD214:${MC_VAR}] VALID_VALUES = '${MC_VALID_VALUES}'.")

    # 2.2 VALUE_MODE validation
    # 2.2.1 Default to SINGLE if not provided
    if(NOT DEFINED MC_VALUE_MODE)
        message(TRACE "[MCT221:${MC_VAR}] VALUE_MODE not provided, defaulting to SINGLE.")
        set(MC_VALUE_MODE SINGLE)
    endif()

    # 2.2.2 Validate against allowed values
    if(NOT MC_VALUE_MODE MATCHES "^(SINGLE|MULTI|SEQUENCE)$")
        message(FATAL_ERROR "[MCE222:${MC_VAR}] Invalid VALUE_MODE '${MC_VALUE_MODE}'.")
    endif()

    message(DEBUG "[MCD222:${MC_VAR}] VALUE_MODE = ${MC_VALUE_MODE}")

    # 2.3. DEFAULT validation
    # 2.3.1. If DEFAULT is not provided, set it based on VALUE_MODE
    if(NOT DEFINED MC_DEFAULT)
        if(MC_VALUE_MODE STREQUAL SINGLE)
            message(TRACE "[MCT231a:${MC_VAR}] DEFAULT not provided, defaulting to first entry in VALID_VALUES.")
            list(GET MC_VALID_VALUES 0 MC_DEFAULT)
        else()
            message(TRACE "[MCT231b:${MC_VAR}] DEFAULT not provided, defaulting to empty list for MULTI and SEQUENCE.")
            set(MC_DEFAULT)
        endif()
    endif()

    # 2.3.2. In SINGLE mode, ensure DEFAULT contains exactly one value
    list(LENGTH MC_DEFAULT _mc_default_len)
    if(MC_VALUE_MODE STREQUAL SINGLE AND NOT _mc_default_len EQUAL 1)
        message(FATAL_ERROR "[MCE232:${MC_VAR}] DEFAULT must contain exactly one value in VALUE_MODE=SINGLE.")
    endif()

    # 2.3.3. Ensure DEFAULT is a subset of VALID_VALUES (Safe for empty strings via IN_LIST)
    if(MC_DEFAULT)
        set(_mc_temp_list ${MC_DEFAULT})
        list(REMOVE_ITEM _mc_temp_list ${MC_VALID_VALUES})
        if(_mc_temp_list)
            message(FATAL_ERROR "[MCE233:${MC_VAR}] DEFAULT contains invalid values.")
        endif()
    endif()

    # 2.3.4. Ensure DEFAULT has no duplicates in MULTI mode
    if(MC_VALUE_MODE STREQUAL MULTI)
        set(_mc_temp_list ${MC_DEFAULT})
        list(REMOVE_DUPLICATES _mc_temp_list)
        list(LENGTH _mc_temp_list _mc_temp_list_len)
        if(NOT _mc_default_len EQUAL _mc_temp_list_len)
            message(FATAL_ERROR "[MCE234:${MC_VAR}] DEFAULT contains duplicate entries in VALUE_MODE=MULTI.")
        endif()
    endif()

    message(DEBUG "[MCD234:${MC_VAR}] DEFAULT = '${MC_DEFAULT}'.")

    # 2.4. TYPE validation
    # 2.4.1 Default to STRING if not provided
    if(NOT DEFINED MC_TYPE)
        message(TRACE "[MCT241:${MC_VAR}] TYPE not provided, defaulting to STRING.")
        set(MC_TYPE STRING)
    endif()

    # 2.4.2 Validate against allowed values
    if(NOT MC_TYPE MATCHES "^(BOOL|FILEPATH|PATH|STRING)$")
        message(FATAL_ERROR "[MCE242:${MC_VAR}] Invalid TYPE '${MC_TYPE}'.")
    endif()

    message(DEBUG "[MCD242:${MC_VAR}] TYPE = ${MC_TYPE}")

    # 2.5. HELP validation
    # 2.5.1 Default to empty string if not provided
    if(NOT DEFINED MC_HELP)
        message(TRACE "[MCT251:${MC_VAR}] HELP not provided, defaulting to empty string.")
        set(MC_HELP "")
    endif()

    message(DEBUG "[MCD252:${MC_VAR}] HELP = '${MC_HELP}'")

    # 2.6. Error handling policy exclusivity
    if(MC_DEFAULT_ON_ERROR AND MC_FATAL_ERROR)
        message(FATAL_ERROR "[MCE260:${MC_VAR}] DEFAULT_ON_ERROR and FATAL_ERROR cannot both be set.")
    endif()

    message(TRACE "[MCD260:${MC_VAR}] DEFAULT_ON_ERROR = ${MC_DEFAULT_ON_ERROR}.")
    message(TRACE "[MCD260:${MC_VAR}] FATAL_ERROR = ${MC_FATAL_ERROR}.")

    # ------------------------------------------------------------
    #  3. CORE LOGIC & VALUE RETRIEVAL
    # ------------------------------------------------------------
    get_property(_mc_is_cached CACHE ${MC_VAR} PROPERTY VALUE SET)
    get_property(_mc_cache_value CACHE ${MC_VAR} PROPERTY VALUE)

    if(NOT DEFINED ${MC_VAR})
        message(TRACE "[MCT310a:${MC_VAR}] The variable is not defined.")
        set(_mc_value ${MC_DEFAULT})
    elseif(NOT _mc_is_cached)
        message(TRACE "[MCT310b:${MC_VAR}] The variable is not cached.")
        set(_mc_value ${${MC_VAR}})
    elseif(NOT "${${MC_VAR}}" STREQUAL "${_mc_cache_value}")
        message(TRACE "[MCT310c:${MC_VAR}] The variable shadows its cache value.")
        set(_mc_value ${${MC_VAR}})
    else()
        message(TRACE "[MCT310d:${MC_VAR}]] The variable is cached.")
        set(_mc_value ${_mc_cache_value})
    endif()

    # ------------------------------------------------------------
    #  4. RESULT VALIDATION
    # ------------------------------------------------------------
    set(_mc_value_is_valid TRUE)
    list(LENGTH _mc_value _mc_value_len)

    # 4.1. Structural validation based on VALUE_MODE
    if(MC_VALUE_MODE STREQUAL SINGLE AND NOT _mc_value_len EQUAL 1)
        message(TRACE "[MCT410a:${MC_VAR}] SINGLE mode requires exactly one value.")
        set(_mc_value_is_valid FALSE)
    elseif(MC_VALUE_MODE STREQUAL MULTI)
        set(_mc_temp_list ${_mc_value})
        list(REMOVE_DUPLICATES _mc_temp_list)
        list(LENGTH _mc_temp_list _mc_temp_list_len)
        if(NOT _mc_value_len EQUAL _mc_temp_list_len)
            message(TRACE "[MCT410b:${MC_VAR}] MULTI mode has duplicate values.")
            set(_mc_value_is_valid FALSE)
        endif()
    elseif(MC_VALUE_MODE STREQUAL SEQUENCE)
        message(TRACE "[MCT410c:${MC_VAR}] No structural validation needed for SEQUENCE mode.")
    endif()

    # 4.2. Subset validation
    if(_mc_value_is_valid AND NOT _mc_value_len EQUAL 0)
        set(_mc_temp_list ${_mc_value})
        list(REMOVE_ITEM _mc_temp_list ${MC_VALID_VALUES})
        if(_mc_temp_list)
            message(TRACE "[MCT420a:${MC_VAR}] Value '${_mc_value}' contains invalid values.")
            set(_mc_value_is_valid FALSE)
        endif()
    endif()

    # 4.3. Error handling policy execution
    if(NOT _mc_value_is_valid)
        if(MC_FATAL_ERROR)
            message(FATAL_ERROR "[MCE430a:${MC_VAR}] Invalid value '${_mc_value}'.")
        elseif(MC_DEFAULT_ON_ERROR)
            message(WARNING "[MCW430b:${MC_VAR}] Invalid value '${_mc_value}'. Resetting to default '${MC_DEFAULT}'.")
            set(_mc_value ${MC_DEFAULT})
        else()
            message(WARNING "[MCW430c:${MC_VAR}] Invalid value '${_mc_value}'. Continuing with this invalid value.")
        endif()
    endif()

    # ------------------------------------------------------------
    #  5. OUTPUT
    # ------------------------------------------------------------
    set(${MC_VAR} ${_mc_value} CACHE ${MC_TYPE} "${MC_HELP}" FORCE)

    if(MC_VALUE_MODE STREQUAL SINGLE)
        set_property(CACHE ${MC_VAR} PROPERTY STRINGS ${MC_VALID_VALUES})
    endif()

    set(${MC_VAR} ${_mc_value} PARENT_SCOPE)

    message(DEBUG "[MCD510:${MC_VAR}] Value = '${${MC_VAR}}'")
endfunction()
