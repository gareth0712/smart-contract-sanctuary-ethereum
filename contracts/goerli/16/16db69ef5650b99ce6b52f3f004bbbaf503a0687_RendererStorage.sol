// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "solmate/utils/SSTORE2.sol";
import "../utils/Multicall.sol";

contract RendererStorage is Multicall {
    error AlreadySetError();
    error NotOwnerError(address caller, address owner);

    event OwnershipTransferred(address previousOwner, address newOwner);

    uint256 constant CROWDFUND_CARD_DATA = 0;
    uint256 constant PARTY_CARD_DATA = 1;

    /// @notice Address allowed to store new data.
    address public owner;

    /// @notice Customization presets by ID, used for rendering cards. Begins at
    ///         1, 0 is reserved to indicate in `getPresetFor()` that a
    ///         party instance use the preset set by the crowdfund instance that
    ///         created it.
    mapping(uint256 => bytes) public customizationPresets;
    /// @notice Customization preset used by a crowdfund or party instance.
    mapping(address => uint256) public getPresetFor;
    /// @notice Addresses where URI data chunks are stored.
    mapping(uint256 => address) public files;

    modifier onlyOwner() {
        address owner_ = owner;
        if (msg.sender != owner_) {
            revert NotOwnerError(msg.sender, owner_);
        }

        _;
    }

    constructor(address _owner) {
        // Set the address allowed to write new data.
        owner = _owner;

        // Write URI data used by V1 of the renderers:

        files[CROWDFUND_CARD_DATA] = SSTORE2.write(
            bytes(
                '<path class="o" d="M118.4 419.5h5.82v1.73h-4.02v1.87h3.74v1.73h-3.74v1.94h4.11v1.73h-5.91v-9Zm9.93 1.76h-2.6v-1.76h7.06v1.76h-2.61v7.24h-1.85v-7.24Zm6.06-1.76h1.84v3.55h3.93v-3.55H142v9h-1.84v-3.67h-3.93v3.67h-1.84v-9Z"/><path class="o" d="M145 413a4 4 0 0 1 4 4v14a4 4 0 0 1-4 4H35a4 4 0 0 1-4-4v-14a4 4 0 0 1 4-4h110m0-1H35a5 5 0 0 0-5 5v14a5 5 0 0 0 5 5h110a5 5 0 0 0 5-5v-14a5 5 0 0 0-5-5Z"/><path d="M239.24 399.83h3.04c1.7 0 2.82 1 2.82 2.55 0 2.1-1.27 3.32-3.57 3.32h-1.97l-.71 3.3h-1.56l1.96-9.17Zm2.34 4.38c1.23 0 1.88-.58 1.88-1.68 0-.73-.49-1.2-1.48-1.2h-1.51l-.6 2.88h1.7Zm3.57 1.86c0-2.27 1.44-3.83 3.57-3.83 1.82 0 3.06 1.25 3.06 3.09 0 2.28-1.43 3.83-3.57 3.83-1.82 0-3.06-1.25-3.06-3.09Zm3.13 1.74c1.19 0 1.93-1.02 1.93-2.52 0-1.06-.62-1.69-1.56-1.69-1.19 0-1.93 1.02-1.93 2.52 0 1.06.62 1.69 1.56 1.69Zm4.74-5.41h1.49l.28 4.73 2.25-4.73h1.64l.23 4.77 2.25-4.77h1.56l-3.3 6.61h-1.62l-.25-5.04-2.42 5.04h-1.63l-.48-6.61Zm9.54 3.66c0-2.27 1.45-3.81 3.6-3.81 2 0 3.05 1.58 2.33 3.92h-4.46c0 1.1.81 1.68 2.05 1.68.8 0 1.45-.2 2.1-.59l-.31 1.46a4.2 4.2 0 0 1-2.04.44c-2.06 0-3.26-1.19-3.26-3.11Zm4.7-1.07c.12-.86-.31-1.46-1.22-1.46s-1.57.61-1.82 1.46h3.05Zm3.46-2.59h1.55l-.28 1.28c.81-1.7 2.56-1.36 2.77-1.29l-.35 1.46c-.18-.06-2.3-.63-2.82 1.68l-.74 3.48h-1.55l1.42-6.61Zm3.91 3.66c0-2.27 1.45-3.81 3.6-3.81 2 0 3.05 1.58 2.33 3.92h-4.46c0 1.1.81 1.68 2.05 1.68.8 0 1.45-.2 2.1-.59l-.31 1.46a4.2 4.2 0 0 1-2.04.44c-2.06 0-3.26-1.19-3.26-3.11Zm4.7-1.07c.12-.86-.31-1.46-1.22-1.46s-1.57.61-1.82 1.46h3.05Zm2.25 1.36c0-2.44 1.36-4.1 3.26-4.1 1 0 1.76.53 2.05 1.31l.79-3.72h1.55l-1.96 9.17h-1.55l.2-.92a2.15 2.15 0 0 1-1.92 1.08c-1.49 0-2.43-1.18-2.43-2.82Zm3 1.51c.88 0 1.51-.58 1.73-1.56l.17-.81c.24-1.1-.31-1.93-1.36-1.93-1.19 0-1.94 1.08-1.94 2.59 0 1.06.55 1.71 1.4 1.71Zm9.6-.01-.25 1.16h-1.55l1.96-9.17h1.55l-.73 3.47a2.35 2.35 0 0 1 1.99-1.05c1.49 0 2.35 1.16 2.35 2.76 0 2.52-1.36 4.16-3.21 4.16-.98 0-1.81-.53-2.1-1.32Zm1.83.01c1.16 0 1.87-1.06 1.87-2.61 0-1.04-.5-1.69-1.39-1.69s-1.52.56-1.73 1.55l-.17.79c-.24 1.14.34 1.97 1.42 1.97Zm5.68 1.16-1.04-6.62h1.52l.66 4.75 2.66-4.75h1.69l-5.31 9.13h-1.73l1.55-2.51Zm23.48-6.8a42.14 42.14 0 0 0-.75 6.01 43.12 43.12 0 0 0 5.58 2.35 42.54 42.54 0 0 0 5.58-2.35 45.32 45.32 0 0 0-.75-6.01c-.91-.79-2.6-2.21-4.83-3.66a42.5 42.5 0 0 0-4.83 3.66Zm13.07-7.95s.82-.29 1.76-.45a14.9 14.9 0 0 0-9.53-3.81c.66.71 1.28 1.67 1.84 2.75 1.84.22 4.07.7 5.92 1.51Zm-2.71 18.36c-2.06-.4-4.05-.97-5.53-1.51a38.65 38.65 0 0 1-5.53 1.51c.12 1.5.35 3.04.76 4.58 0 0 1.54 1.82 4.78 2.8 3.23-.98 4.78-2.8 4.78-2.8.4-1.53.64-3.08.76-4.58Zm-13.77-18.37a22.3 22.3 0 0 1 5.93-1.51 12.4 12.4 0 0 1 1.84-2.75 14.97 14.97 0 0 0-9.53 3.81c.95.16 1.76.45 1.76.45Zm-4.72 8.77a25.74 25.74 0 0 0 3.58 2.94 37.48 37.48 0 0 1 4.08-4.04c.27-1.56.77-3.57 1.46-5.55a25.24 25.24 0 0 0-4.34-1.63s-2.35.42-4.81 2.74c-.77 3.29.04 5.54.04 5.54Zm25.92 0s.81-2.25.04-5.54c-2.46-2.31-4.81-2.74-4.81-2.74-1.53.42-2.99.99-4.34 1.63a37.79 37.79 0 0 1 1.46 5.55 37.44 37.44 0 0 1 4.08 4.04 25.86 25.86 0 0 0 3.58-2.94Zm-26.38.2s-.66-.56-1.27-1.3c-.7 3.34-.27 6.93 1.46 10.16.28-.93.8-1.94 1.46-2.97a22.32 22.32 0 0 1-1.66-5.88Zm8.24 14.27a22.07 22.07 0 0 1-4.27-4.38c-1.22.06-2.36 0-3.3-.22a14.91 14.91 0 0 0 8.07 6.34c-.34-.9-.5-1.75-.5-1.75Zm18.6-14.27s.66-.56 1.27-1.3c.7 3.34.27 6.93-1.46 10.16-.28-.93-.8-1.94-1.46-2.97a22.32 22.32 0 0 0 1.66-5.88Zm-8.24 14.27a22.07 22.07 0 0 0 4.27-4.38c1.22.06 2.36 0 3.3-.22a14.91 14.91 0 0 1-8.07 6.34c.34-.9.5-1.75.5-1.75ZM330 391.84l-4.12 2.45 1.26 3.91h5.72l1.26-3.91-4.12-2.45Zm-11.4 19.74 4.18 2.35 2.75-3.05-2.86-4.95-4.02.86-.06 4.79Zm22.79 0-.06-4.79-4.02-.86-2.86 4.95 2.75 3.05 4.18-2.35Z" style="fill:#00c1fa"/><use height="300" transform="matrix(1 0 0 .09 29.85 444)" width="300.15" xlink:href="#a"/><use height="21.15" transform="translate(30 446.92)" width="300" xlink:href="#b"/><g><path d="m191.54 428.67-28.09-24.34A29.98 29.98 0 0 0 143.8 397H30a15 15 0 0 0-15 15v98a15 15 0 0 0 15 15h300a15 15 0 0 0 15-15v-59a15 15 0 0 0-15-15H211.19a30 30 0 0 1-19.65-7.33Z" style="fill:url(#i)"/></g></svg>'
            )
        );

        files[PARTY_CARD_DATA] = SSTORE2.write(
            bytes(
                ' d="M188 444.3h2.4l2.6 8.2 2.7-8.2h2.3l-3.7 10.7h-2.8l-3.5-10.7zm10.5 5.3c0-3.2 2.2-5.6 5.3-5.6 3.1 0 5.3 2.3 5.3 5.6 0 3.2-2.2 5.5-5.3 5.5-3.1.1-5.3-2.2-5.3-5.5zm5.3 3.5c1.8 0 3-1.3 3-3.4 0-2.1-1.1-3.5-3-3.5s-3 1.3-3 3.5c0 2.1 1.1 3.4 3 3.4zm8.7-6.7h-3.1v-2.1h8.4v2.1h-3.1v8.6h-2.2v-8.6zm6.9-2.1h2.2V455h-2.2v-10.7zm4.3 0h2.9l4 8.2v-8.2h2.1V455h-2.9l-4-8.2v8.2h-2.1v-10.7zm10.6 5.4c0-3.4 2.3-5.6 6-5.6 1.2 0 2.3.2 3.1.6v2.3c-.9-.6-1.9-.8-3.1-.8-2.4 0-3.8 1.3-3.8 3.5 0 2.1 1.3 3.4 3.5 3.4.5 0 .9-.1 1.3-.2v-2.2h-2.2v-1.9h4.3v5.6c-1 .5-2.2.8-3.4.8-3.5 0-5.7-2.2-5.7-5.5zm15.1-5.4h4.3c2.3 0 3.7 1.3 3.7 3.5s-1.4 3.5-3.7 3.5h-2.1v3.7h-2.2v-10.7zm4.1 5c1.1 0 1.6-.5 1.6-1.5s-.5-1.5-1.6-1.5h-1.9v2.9h1.9zm4.8.3c0-3.2 2.2-5.6 5.3-5.6 3.1 0 5.3 2.3 5.3 5.6 0 3.2-2.2 5.5-5.3 5.5-3.1.1-5.3-2.2-5.3-5.5zm5.3 3.5c1.8 0 3-1.3 3-3.4 0-2.1-1.1-3.5-3-3.5s-3 1.3-3 3.5c0 2.1 1.1 3.4 3 3.4zm5.8-8.8h2.3l1.7 7.8 1.9-7.8h2.4l1.8 7.8 1.8-7.8h2.3l-2.7 10.7h-2.5l-1.9-8.2-1.8 8.2h-2.5l-2.8-10.7zm15.4 0h6.9v2.1H287v2.2h4.5v2.1H287v2.3h4.9v2.1h-7v-10.8zm9 0h4.5c2 0 3.3 1.3 3.3 3.2 0 1.9-1.2 3.1-3 3.2l3.5 4.3h-2.7l-3.5-4.4v4.4h-2.1v-10.7zm4.1 4.8c1 0 1.5-.5 1.5-1.4 0-.9-.6-1.4-1.5-1.4h-2v2.9h2zM30 444.3h4.3c3 0 5.2 2.1 5.2 5.4s-2.1 5.4-5.2 5.4H30v-10.8zm4 8.6c2.1 0 3.2-1.2 3.2-3.2s-1.2-3.3-3.2-3.3h-1.8v6.5H34zm7.7-8.6h2.2V455h-2.2v-10.7zm4.8 10V452c1 .7 2.1 1.1 3.2 1.1s1.7-.5 1.7-1.2-.4-1-1.2-1.2l-1.2-.3c-1.8-.5-2.7-1.5-2.7-3.1 0-2 1.5-3.2 3.9-3.2 1 0 2.1.2 2.9.7v2.3c-.9-.6-1.9-.8-3-.8-.9 0-1.6.4-1.6 1.1 0 .6.4.9 1.2 1.1l1.3.4c1.8.5 2.6 1.4 2.6 3.1 0 2.1-1.5 3.4-3.8 3.4-1.1-.2-2.3-.5-3.3-1.1zm12-7.9h-3.1v-2.1h8.4v2.1h-3.1v8.6h-2.2v-8.6zm7.5-2.1h4.5c2 0 3.3 1.3 3.3 3.2 0 1.9-1.2 3.1-3 3.2l3.5 4.3h-2.7l-3.5-4.4v4.4H66v-10.7zm4.1 4.8c1 0 1.5-.5 1.5-1.4s-.6-1.4-1.5-1.4h-2v2.9h2zm6.1-4.8h2.2V455h-2.2v-10.7zm5 0h4.5c2 0 3.2 1.1 3.2 2.8 0 1.1-.5 1.9-1.4 2.3 1.1.3 1.8 1.3 1.8 2.5 0 1.9-1.3 3.1-3.5 3.1h-4.6v-10.7zm4.2 4.4c.9 0 1.4-.5 1.4-1.3s-.5-1.3-1.4-1.3h-2.1v2.5l2.1.1zm.3 4.4c.9 0 1.5-.5 1.5-1.3s-.6-1.3-1.5-1.3h-2.4v2.6h2.4zm5.7-2.5v-6.3h2.2v6.3c0 1.6.9 2.5 2.3 2.5s2.3-.9 2.3-2.5v-6.3h2.2v6.3c0 2.9-1.7 4.6-4.5 4.6s-4.6-1.7-4.5-4.6zm14.2-4.2h-3.1v-2.1h8.4v2.1h-3.1v8.6h-2.2v-8.6zm7.5-2.1h2.2V455h-2.2v-10.7zm4.5 5.3c0-3.2 2.2-5.6 5.3-5.6s5.3 2.3 5.3 5.6-2.2 5.5-5.3 5.5-5.3-2.2-5.3-5.5zm5.3 3.5c1.8 0 3-1.3 3-3.5s-1.2-3.5-3-3.5-3 1.3-3 3.5 1.1 3.5 3 3.5zm7.5-8.8h2.9l4 8.2v-8.2h2.1V455h-2.9l-4-8.2v8.2h-2.1v-10.7zm11.7 10V452c1 .7 2.1 1.1 3.2 1.1s1.7-.5 1.7-1.2-.4-1-1.2-1.2l-1.2-.3c-1.8-.5-2.6-1.5-2.6-3.1 0-2 1.5-3.2 3.9-3.2 1.1 0 2.1.2 2.9.7v2.3c-.9-.6-1.9-.8-3-.8-.9 0-1.6.4-1.6 1.1 0 .6.4.9 1.2 1.1l1.3.4c1.8.5 2.6 1.4 2.6 3.1 0 2.1-1.5 3.4-3.8 3.4a9.7 9.7 0 0 1-3.4-1.1zM30 259.3h4.3c2.2 0 3.7 1.3 3.7 3.5s-1.4 3.5-3.7 3.5h-2.1v3.7H30v-10.7zm4.1 5c1.1 0 1.6-.5 1.6-1.5s-.5-1.5-1.6-1.5h-1.9v2.9h1.9zm6.1-5h4.5c2 0 3.3 1.3 3.3 3.2 0 1.9-1.2 3.1-3 3.2l3.5 4.3h-2.7l-3.5-4.4v4.4h-2.1v-10.7zm4.1 4.8c1 0 1.5-.5 1.5-1.4s-.6-1.4-1.5-1.4h-2v2.9h2zm5.4.5c0-3.2 2.2-5.6 5.3-5.6s5.3 2.3 5.3 5.6-2.2 5.5-5.3 5.5-5.3-2.2-5.3-5.5zm5.3 3.5c1.8 0 3-1.3 3-3.5s-1.2-3.5-3-3.5-3 1.3-3 3.5 1.1 3.5 3 3.5zm7.6-8.8h4.3c2.2 0 3.7 1.3 3.7 3.5s-1.4 3.5-3.7 3.5h-2.1v3.7h-2.2v-10.7zm4.1 5c1.1 0 1.6-.5 1.6-1.5s-.6-1.5-1.6-1.5h-1.9v2.9h1.9zm5.4.4c0-3.2 2.2-5.6 5.3-5.6s5.3 2.3 5.3 5.6-2.2 5.5-5.3 5.5-5.3-2.3-5.3-5.5zm5.4 3.4c1.8 0 3-1.3 3-3.5s-1.2-3.5-3-3.5-3 1.3-3 3.5 1.1 3.5 3 3.5zm7.2 1.2V267c1 .7 2.1 1.1 3.2 1.1s1.7-.5 1.7-1.2-.4-1-1.2-1.2l-1.2-.3c-1.8-.5-2.7-1.5-2.7-3.1 0-2 1.5-3.2 3.9-3.2 1.1 0 2.1.2 2.9.7v2.3c-.9-.6-1.9-.8-3-.8-.9 0-1.6.4-1.6 1.1 0 .6.4.9 1.2 1.1l1.3.4c1.8.5 2.6 1.4 2.6 3.1 0 2.1-1.5 3.4-3.8 3.4-1.1-.2-2.3-.5-3.3-1.1zm12.2-10h2.8l3.7 10.7h-2.3l-.8-2.5h-4l-.8 2.5h-2.2l3.6-10.7zm2.8 6.3-1.4-4.2-1.4 4.2h2.8zm5.7-6.3h2.2v8.6h4.7v2.1h-6.9v-10.7zm9.1 10V267c1 .7 2.1 1.1 3.2 1.1s1.7-.5 1.7-1.2-.4-1-1.2-1.2l-1.2-.3c-1.8-.5-2.7-1.5-2.7-3.1 0-2 1.5-3.2 3.9-3.2 1.1 0 2.1.2 2.9.7v2.3c-.9-.6-1.9-.8-3-.8-.9 0-1.6.4-1.6 1.1 0 .6.4.9 1.2 1.1l1.3.4c1.8.5 2.6 1.4 2.6 3.1 0 2.1-1.5 3.4-3.8 3.4-1.1-.2-2.3-.5-3.3-1.1zm-84.5-70h2.9l4 8.2v-8.2H39V210h-2.9l-4-8.2v8.2H30v-10.7zm14.7 0h2.8l3.7 10.7h-2.3l-.8-2.6h-4l-.8 2.6H41l3.7-10.7zm2.8 6.2-1.4-4.2-1.4 4.2h2.8zm5.7-6.2h3.3l2.5 8.2 2.5-8.2h3.3V210h-2v-8.6L60 210h-2.1l-2.7-8.5v8.5h-2v-10.7zm14.4 0h6.9v2.1h-4.8v2.2h4.4v2.1h-4.4v2.3h4.9v2.1h-7v-10.8z" /><path d="M239.24 24.83h3.04c1.7 0 2.82 1 2.82 2.55 0 2.1-1.27 3.32-3.57 3.32h-1.97l-.71 3.3h-1.56l1.96-9.17Zm2.34 4.38c1.23 0 1.88-.58 1.88-1.68 0-.73-.49-1.2-1.48-1.2h-1.51l-.6 2.88h1.7Zm3.57 1.86c0-2.27 1.44-3.83 3.57-3.83 1.82 0 3.06 1.25 3.06 3.09 0 2.28-1.43 3.83-3.57 3.83-1.82 0-3.06-1.25-3.06-3.09Zm3.13 1.74c1.19 0 1.93-1.02 1.93-2.52 0-1.06-.62-1.69-1.56-1.69-1.19 0-1.93 1.02-1.93 2.52 0 1.06.62 1.69 1.56 1.69Zm4.74-5.41h1.49l.28 4.73 2.25-4.73h1.64l.23 4.77 2.25-4.77h1.56l-3.3 6.61h-1.62l-.25-5.04-2.42 5.04h-1.63l-.48-6.61Zm9.54 3.66c0-2.27 1.45-3.81 3.6-3.81 2 0 3.05 1.58 2.33 3.92h-4.46c0 1.1.81 1.68 2.05 1.68.8 0 1.45-.2 2.1-.59l-.31 1.46a4.2 4.2 0 0 1-2.04.44c-2.06 0-3.26-1.19-3.26-3.11Zm4.7-1.07c.12-.86-.31-1.46-1.22-1.46s-1.57.61-1.82 1.46h3.05Zm3.46-2.59h1.55l-.28 1.28c.81-1.7 2.56-1.36 2.77-1.29l-.35 1.46c-.18-.06-2.3-.63-2.82 1.68l-.74 3.48h-1.55l1.42-6.61Zm3.91 3.66c0-2.27 1.45-3.81 3.6-3.81 2 0 3.05 1.58 2.33 3.92h-4.46c0 1.1.81 1.68 2.05 1.68.8 0 1.45-.2 2.1-.59l-.31 1.46a4.2 4.2 0 0 1-2.04.44c-2.06 0-3.26-1.19-3.26-3.11Zm4.7-1.07c.12-.86-.31-1.46-1.22-1.46s-1.57.61-1.82 1.46h3.05Zm2.25 1.36c0-2.44 1.36-4.1 3.26-4.1 1 0 1.76.53 2.05 1.31l.79-3.72h1.55l-1.96 9.17h-1.55l.2-.92a2.15 2.15 0 0 1-1.92 1.08c-1.49 0-2.43-1.18-2.43-2.82Zm3 1.51c.88 0 1.51-.58 1.73-1.56l.17-.81c.24-1.1-.31-1.93-1.36-1.93-1.19 0-1.94 1.08-1.94 2.59 0 1.06.55 1.71 1.4 1.71Zm9.6-.01-.25 1.16h-1.55l1.96-9.17h1.55l-.73 3.47a2.35 2.35 0 0 1 1.99-1.05c1.49 0 2.35 1.16 2.35 2.76 0 2.52-1.36 4.16-3.21 4.16-.98 0-1.81-.53-2.1-1.32Zm1.83.01c1.16 0 1.87-1.06 1.87-2.61 0-1.04-.5-1.69-1.39-1.69s-1.52.56-1.73 1.55l-.17.79c-.24 1.14.34 1.97 1.42 1.97Zm5.68 1.16-1.04-6.62h1.52l.66 4.75 2.66-4.75h1.69l-5.31 9.13h-1.73l1.55-2.51Zm23.47-6.8c.91-.79 2.6-2.21 4.83-3.66a42.5 42.5 0 0 1 4.83 3.66c.23 1.18.62 3.36.75 6.01a43.12 43.12 0 0 1-5.58 2.35 42.54 42.54 0 0 1-5.58-2.35c.14-2.65.53-4.83.75-6.01Zm13.07-7.95s.82-.29 1.76-.45a14.9 14.9 0 0 0-9.53-3.81c.66.71 1.28 1.67 1.84 2.75 1.84.22 4.07.7 5.92 1.51Zm-2.71 18.36c-2.06-.4-4.05-.97-5.53-1.51a38.65 38.65 0 0 1-5.53 1.51c.12 1.5.35 3.04.76 4.58 0 0 1.54 1.82 4.78 2.8 3.23-.98 4.78-2.8 4.78-2.8.4-1.53.64-3.08.76-4.58Zm-13.77-18.37a22.3 22.3 0 0 1 5.93-1.51 12.4 12.4 0 0 1 1.84-2.75 14.97 14.97 0 0 0-9.53 3.81c.95.16 1.76.45 1.76.45Zm-4.72 8.77a25.74 25.74 0 0 0 3.58 2.94 37.48 37.48 0 0 1 4.08-4.04c.27-1.56.77-3.57 1.46-5.55a25.24 25.24 0 0 0-4.34-1.63s-2.35.42-4.81 2.74c-.77 3.29.04 5.54.04 5.54Zm25.92 0s.81-2.25.04-5.54c-2.46-2.31-4.81-2.74-4.81-2.74-1.53.42-2.99.99-4.34 1.63a37.79 37.79 0 0 1 1.46 5.55 37.44 37.44 0 0 1 4.08 4.04 25.86 25.86 0 0 0 3.58-2.94Zm-26.38.2s-.66-.56-1.27-1.3c-.7 3.34-.27 6.93 1.46 10.16.28-.93.8-1.94 1.46-2.97a22.32 22.32 0 0 1-1.66-5.88Zm8.24 14.27a22.07 22.07 0 0 1-4.27-4.38c-1.22.06-2.36 0-3.3-.22a14.91 14.91 0 0 0 8.07 6.34c-.34-.9-.5-1.75-.5-1.75Zm18.6-14.27s.66-.56 1.27-1.3c.7 3.34.27 6.93-1.46 10.16-.28-.93-.8-1.94-1.46-2.97a22.32 22.32 0 0 0 1.66-5.88Zm-8.24 14.27a22.07 22.07 0 0 0 4.27-4.38c1.22.06 2.36 0 3.3-.22a14.91 14.91 0 0 1-8.07 6.34c.34-.9.5-1.75.5-1.75Zm-5.18-25.66-4.12 2.45 1.26 3.91h5.72l1.26-3.91-4.12-2.45Zm-11.4 19.74 4.18 2.35 2.75-3.05-2.86-4.95-4.02.86-.06 4.79Zm22.79 0-.06-4.79-4.02-.86-2.86 4.95 2.75 3.05 4.18-2.35Z" style="fill:#00c1fa"/><path d="M106.67 109.1a304.9 304.9 0 0 0-3.72-10.89c5.04-5.53 35.28-40.74 24.54-68.91 10.57 10.67 8.19 28.85 3.59 41.95-4.79 13.14-13.43 26.48-24.4 37.84Zm30.89 20.82c-5.87 6.12-20.46 17.92-21.67 18.77a99.37 99.37 0 0 0 7.94 6.02 133.26 133.26 0 0 0 20.09-18.48 353.47 353.47 0 0 0-6.36-6.31Zm-29.65-16.74a380.9 380.9 0 0 1 3.13 11.56c-4.8-1.37-8.66-2.53-12.36-3.82a123.4 123.4 0 0 1-21.16 13.21l15.84 5.47c14.83-8.23 28.13-20.82 37.81-34.68 0 0 8.56-12.55 12.42-23.68 2.62-7.48 4.46-16.57 3.49-24.89-2.21-12.27-6.95-15.84-9.32-17.66 6.16 5.72 3.25 27.8-2.79 39.89-6.08 12.16-15.73 24.27-27.05 34.59Zm59.05-37.86c-.03 7.72-3.05 15.69-6.44 22.69 1.7 2.2 3.18 4.36 4.42 6.49 7.97-16.51 3.74-26.67 2.02-29.18ZM61.18 128.51l12.5 4.3a101.45 101.45 0 0 0 21.42-13.19 163.26 163.26 0 0 1-10.61-4.51 101.28 101.28 0 0 1-23.3 13.4Zm87.78-42.73c.86.77 5.44 5.18 6.75 6.59 6.39-16.61.78-28.86-1.27-30.56.72 8.05-2.02 16.51-5.48 23.98Zm-14.29 40.62-2.47-15.18a142.42 142.42 0 0 1-35.74 29.45c6.81 2.36 12.69 4.4 15.45 5.38a115.98 115.98 0 0 0 22.75-19.66Zm-42.62 34.73c4.48 2.93 12.94 4.24 18.8 1.23 6.03-3.84-.6-8.34-8.01-9.88-9.8-2.03-16.82 1.22-13.4 6.21.41.6 1.19 1.5 2.62 2.44m-1.84.4c-3.56-2.37-6.77-7.2-.23-10.08 10.41-3.43 28.39 3.2 24.99 9.22-.58 1.04-1.46 1.6-2.38 2.19h-.03v.02h-.03v.02h-.03c-7.04 3.65-17.06 2.13-22.3-1.36m5.48-3.86a4.94 4.94 0 0 0 5.06.49l1.35-.74-4.68-2.38-1.47.79c-.38.22-1.53.88-.26 1.84m-1.7.59c-2.35-1.57-.78-2.61-.02-3.11 1.09-.57 2.19-1.15 3.28-1.77 6.95 3.67 7.22 3.81 13.19 6.17l-1.38.81c-1.93-.78-4.52-1.82-6.42-2.68.86 1.4 1.99 3.27 2.9 4.64l-1.68.87c-.75-1.28-1.76-2.99-2.47-4.29-3.19 2.06-6.99-.36-7.42-.64" style="fill:url(#f2)"/><path d="M159.13 52.37C143.51 24.04 119.45 15 103.6 15c-11.92 0-25.97 5.78-36.84 13.17 9.54 4.38 21.86 15.96 22.02 16.11-7.94-3.05-17.83-6.72-33.23-7.87a135.1 135.1 0 0 0-19.77 20.38c.77 7.66 2.88 15.68 2.88 15.68-6.28-4.75-11.02-4.61-18 9.45-5.4 12.66-6.93 24.25-4.65 33.18 0 0 4.72 26.8 36.23 40.07-1.3-4.61-1.58-9.91-.93-15.73a87.96 87.96 0 0 1-15.63-9.87c.79-6.61 2.79-13.82 6-21.36 4.42-10.66 4.35-15.14 4.35-15.19.03.07 5.48 12.43 12.95 22.08 4.23-8.84 9.46-16.08 13.67-21.83l-3.77-6.75a143.73 143.73 0 0 1 18.19-18.75c2.05 1.07 4.79 2.47 6.84 3.58 8.68-7.27 19.25-14.05 30.56-18.29-7-11.49-16.02-19.27-16.02-19.27s27.7 2.74 42.02 15.69a25.8 25.8 0 0 1 8.65 2.89ZM28.58 107.52a70.1 70.1 0 0 0-2.74 12.52 55.65 55.65 0 0 1-6.19-8.84 69.17 69.17 0 0 1 2.65-12.1c1.77-5.31 3.35-5.91 5.86-2.23v-.05c2.14 3.07 1.81 6.14.42 10.7ZM61.69 72.2l-.05.05a221.85 221.85 0 0 1-7.77-18.1l.14-.14a194.51 194.51 0 0 1 18.56 6.98 144.44 144.44 0 0 0-10.88 11.22Zm54.84-47.38c-4.42.7-9.02 1.95-13.67 3.72a65.03 65.03 0 0 0-7.81-5.31 66.04 66.04 0 0 1 13.02-3.54c1.53-.19 6.23-.79 10.32 2.42v-.05c2.47 1.91.14 2.37-1.86 2.75Z" style="fill:url(#h)"/>'
            )
        );
    }

    /// @notice Transfer ownership to a new owner.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(address newOwner) external onlyOwner {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /// @notice Write data to be accessed by a given file key.
    /// @param key The key to access the written data.
    /// @param data The data to be written.
    function writeFile(uint256 key, string memory data) external onlyOwner {
        files[key] = SSTORE2.write(bytes(data));
    }

    /// @notice Read data using a given file key.
    /// @param key The key to access the stored data.
    /// @return data The data stored at the given key.
    function readFile(uint256 key) external view returns (string memory data) {
        return string(SSTORE2.read(files[key]));
    }

    /// @notice Create or set a customization preset for renderers to use.
    /// @param id The ID of the customization preset.
    /// @param customizationData Data decoded by renderers used to render the SVG according to the preset.
    function createCustomizationPreset(
        uint256 id,
        bytes memory customizationData
    ) external onlyOwner {
        customizationPresets[id] = customizationData;
    }

    /// @notice For crowdfund or party instances to set the customization preset they want to use.
    /// @param id The ID of the customization preset.
    function useCustomizationPreset(uint256 id) external {
        getPresetFor[msg.sender] = id;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

library LibRawResult {
    // Revert with the data in `b`.
    function rawRevert(bytes memory b) internal pure {
        assembly {
            revert(add(b, 32), mload(b))
        }
    }

    // Return with the data in `b`.
    function rawReturn(bytes memory b) internal pure {
        assembly {
            return(add(b, 32), mload(b))
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../utils/LibRawResult.sol";

abstract contract Multicall {
    using LibRawResult for bytes;

    /// @notice Perform multiple delegatecalls on ourselves.
    function multicall(bytes[] calldata multicallData) external {
        for (uint256 i; i < multicallData.length; ++i) {
            (bool s, bytes memory r) = address(this).delegatecall(multicallData[i]);
            if (!s) {
                r.rawRevert();
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    uint256 internal constant DATA_OFFSET = 1; // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.

    /*//////////////////////////////////////////////////////////////
                               WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    function write(bytes memory data) internal returns (address pointer) {
        // Prefix the bytecode with a STOP opcode to ensure it cannot be called.
        bytes memory runtimeCode = abi.encodePacked(hex"00", data);

        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x600B             | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xf3    |  0xf3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            hex"60_0B_59_81_38_03_80_92_59_39_F3", // Returns all code in the contract except for the first 11 (0B in hex) bytes.
            runtimeCode // The bytecode we want the contract to have after deployment. Capped at 1 byte less than the code size limit.
        );

        /// @solidity memory-safe-assembly
        assembly {
            // Deploy a new contract with the generated creation code.
            // We start 32 bytes into the code to avoid copying the byte length.
            pointer := create(0, add(creationCode, 32), mload(creationCode))
        }

        require(pointer != address(0), "DEPLOYMENT_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    function read(address pointer) internal view returns (bytes memory) {
        return readBytecode(pointer, DATA_OFFSET, pointer.code.length - DATA_OFFSET);
    }

    function read(address pointer, uint256 start) internal view returns (bytes memory) {
        start += DATA_OFFSET;

        return readBytecode(pointer, start, pointer.code.length - start);
    }

    function read(
        address pointer,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory) {
        start += DATA_OFFSET;
        end += DATA_OFFSET;

        require(pointer.code.length >= end, "OUT_OF_BOUNDS");

        return readBytecode(pointer, start, end - start);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function readBytecode(
        address pointer,
        uint256 start,
        uint256 size
    ) private view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 31 to size and running the result through the logic above ensures
            // the memory pointer remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 32), 31), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(data, size)

            // Copy the code into memory right after the 32 bytes we used to store the size.
            extcodecopy(pointer, add(data, 32), start, size)
        }
    }
}