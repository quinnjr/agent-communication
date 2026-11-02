use std::process::ExitCode;

#[tokio::main]
async fn main() -> ExitCode {
    agent_communication::cli::main().await
}
