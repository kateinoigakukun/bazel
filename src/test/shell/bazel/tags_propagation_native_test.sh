#!/bin/bash
#
# Copyright 2019 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Tests target's tags propagation with rules defined in Skylark.
# Tests for https://github.com/bazelbuild/bazel/issues/7766

# Load the test setup defined in the parent directory
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${CURRENT_DIR}/../integration_test_setup.sh" \
  || { echo "integration_test_setup.sh not found!" >&2; exit 1; }

PLATFORM="$(uname -s | tr 'A-Z' 'a-z')"

# Test a basic native rule which has tags, that should be propagated
function test_cc_library_tags_propagated() {
  mkdir -p test
  cat > test/BUILD <<EOF
package(default_visibility = ["//visibility:public"])
cc_library(
  name = 'test',
  srcs = [ 'test.cc' ],
  tags = ["no-cache", "no-remote", "local"]
)
EOF
  cat > test/test.cc <<EOF
#include <iostream>
int main() { std::cout << "Hello test!" << std::endl; return 0; }
EOF

  bazel aquery --experimental_allow_tags_propagation 'mnemonic("CppCompile", //test:test)' > output1 2> $TEST_log \
      || fail "should have generated output successfully"

  assert_contains "ExecutionInfo: {" output1
  assert_contains "local:" output1
  assert_contains "no-cache:" output1
  assert_contains "no-remote:" output1

  bazel aquery --experimental_allow_tags_propagation 'mnemonic("CppLink", outputs(".*/libtest.a", //test:test))' > output1 2> $TEST_log \
      || fail "should have generated output successfully"

  assert_contains "ExecutionInfo: {" output1
  assert_contains "local:" output1
  assert_contains "no-cache:" output1
  assert_contains "no-remote:" output1

  bazel aquery --experimental_allow_tags_propagation 'mnemonic("CppLink", outputs(".*/libtest.so", //test:test))' > output1 2> $TEST_log \
      || fail "should have generated output successfully"

  assert_contains "ExecutionInfo: {" output1
  assert_contains "local:" output1
  assert_contains "no-cache:" output1
  assert_contains "no-remote:" output1
}

function test_cc_binary_tags_propagated() {

 mkdir -p test
  cat > test/BUILD <<EOF
package(default_visibility = ["//visibility:public"])
cc_binary(
  name = "test",
  srcs = ["test.cc"],
  tags = ["no-cache", "no-remote", "local"]
)
EOF
  cat > test/test.cc <<EOF
#include <iostream>
int main() { std::cout << "Hello test!" << std::endl; return 0; }
EOF

  bazel aquery --experimental_allow_tags_propagation 'mnemonic("CppCompile", //test:test)' > output1 2> $TEST_log \
      || fail "should have generated output successfully"

  assert_contains "ExecutionInfo: {" output1
  assert_contains "local:" output1
  assert_contains "no-cache:" output1
  assert_contains "no-remote:" output1

  bazel aquery --experimental_allow_tags_propagation 'mnemonic("CppLink", //test:test)' > output1 2> $TEST_log \
      || fail "should have generated output successfully"

  assert_contains "ExecutionInfo: {" output1
  assert_contains "local:" output1
  assert_contains "no-cache:" output1
  assert_contains "no-remote:" output1
}

function test_genrule_tags_propagated() {
  mkdir -p test
  cat > test/BUILD <<EOF
package(default_visibility = ["//visibility:public"])
genrule(
  name = 'test',
  outs = [ 'test.out' ],
  cmd = "echo hello > \$@",
  tags = ["no-cache", "no-remote", "local"]
)
EOF

  bazel aquery --experimental_allow_tags_propagation '//test:test' > output1 2> $TEST_log \
      || fail "should have generated output successfully"

  assert_contains "ExecutionInfo: {" output1
  assert_contains "local:" output1
  assert_contains "no-cache:" output1
  assert_contains "no-remote:" output1
}

# Test a native test rule rule which has tags, that should be propagated (independent of flags)
function test_test_rules_tags_propagated() {
  mkdir -p test
  cat > test/BUILD <<EOF
package(default_visibility = ["//visibility:public"])
cc_test(
  name = 'test',
  srcs = [ 'test.cc' ],
  tags = ["no-cache", "no-remote", "local"]
)
EOF
  cat > test/test.cc <<EOF
#include <iostream>
int main() { std::cout << "Hello test!" << std::endl; return 0; }
EOF

  bazel aquery --experimental_allow_tags_propagation=false '//test:test' > output1 2> $TEST_log \
      || fail "should have generated output successfully"

  assert_contains "ExecutionInfo: {" output1
  assert_contains "local:" output1
  assert_contains "no-cache:" output1
  assert_contains "no-remote:" output1
}

# Test a basic native rule which has tags, that should not be propagated
# as --experimental_allow_tags_propagation flag set to false
function test_cc_library_tags_not_propagated_when_incompatible_flag_off() {
  mkdir -p test
  cat > test/BUILD <<EOF
package(default_visibility = ["//visibility:public"])
cc_library(
  name = 'test',
  srcs = [ 'test.cc' ],
  tags = ["no-cache", "no-remote", "local"]
)
EOF
  cat > test/test.cc <<EOF
#include <iostream>
int main() { std::cout << "Hello test!" << std::endl; return 0; }
EOF

  bazel aquery --experimental_allow_tags_propagation=false '//test:test' > output1 2> $TEST_log \
      || fail "should have generated output successfully"

  assert_not_contains "local:" output1
  assert_not_contains "no-cache:" output1
  assert_not_contains "no-remote:" output1
}

function test_cc_binary_tags_not_propagated_when_incompatible_flag_off() {

 mkdir -p test
  cat > test/BUILD <<EOF
package(default_visibility = ["//visibility:public"])
cc_binary(
  name = "test",
  srcs = ["test.cc"],
  tags = ["no-cache", "no-remote", "local"]
)
EOF
  cat > test/test.cc <<EOF
#include <iostream>
int main() { std::cout << "Hello test!" << std::endl; return 0; }
EOF

  bazel aquery --experimental_allow_tags_propagation=false '//test:test' > output1 2> $TEST_log \
      || fail "should have generated output successfully"

  assert_not_contains "local:" output1
  assert_not_contains "no-cache:" output1
  assert_not_contains "no-remote:" output1
}

run_suite "tags propagation: skylark rule tests"
