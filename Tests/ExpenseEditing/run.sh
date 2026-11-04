#!/bin/sh
set -eu
cd "$(dirname "$0")/../.."
check_dir=$(mktemp -d /tmp/somai-edit-checks.XXXXXX)
trap 'rm -rf "$check_dir"' EXIT
xcrun swiftc -parse-as-library -module-cache-path "$check_dir/cache" \
    extReader/Utils/ExpenseReport.swift extReader/Utils/PreparedReport.swift \
    extReader/Utils/ExpenseReportState.swift extReader/Utils/ManualExpenseInput.swift \
    extReader/Utils/ExpenseService.swift extReader/Utils/AppConfig.swift \
    Tests/ExpenseEditing/Support.swift Tests/ExpenseEditing/main.swift -o "$check_dir/checks"
"$check_dir/checks"
