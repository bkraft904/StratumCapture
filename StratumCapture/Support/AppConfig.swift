import Foundation

/// Points this app at the already-deployed `/analyze` Lambda — the exact
/// same backend the web app (stratum-xray-passport) calls. No new backend
/// work is needed for the findings part of this flow.
///
/// If this URL ever changes (redeploy, new region, new stack name), get the
/// current value with:
///   aws cloudformation describe-stacks --stack-name stratum-scan-lab \
///     --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" --output text
enum AppConfig {
    static let analyzeAPIURL: URL? = URL(string: "https://iz8dj1ub5c.execute-api.us-east-1.amazonaws.com/analyze")
}
