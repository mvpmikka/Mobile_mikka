// Not an HttpException — this is thrown from CallService.initiate and
// caught inside CallGateway's WebSocket handler (there is no HTTP
// response pipeline for socket events), which translates it into a
// call:busy message to the caller instead of a generic call:failed.
export class CallBusyError extends Error {}
