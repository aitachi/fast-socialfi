// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/core/CircleFactory.sol";
import "../contracts/core/CircleToken.sol";
import "../contracts/core/BondingCurve.sol";

contract CircleFactoryTest is Test {
    CircleFactory public factory;
    address public owner;
    address public user1;
    address public user2;
    address public platformTreasury;

    event CircleCreated(
        uint256 indexed circleId,
        address indexed owner,
        address indexed tokenAddress,
        string name,
        string symbol,
        BondingCurve.CurveType curveType
    );

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        platformTreasury = makeAddr("treasury");

        // Fund test accounts
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(platformTreasury, 0);

        // Deploy factory
        factory = new CircleFactory(platformTreasury);
    }

    function testDeployment() public {
        assertEq(factory.circleCount(), 0);
        assertEq(factory.platformTreasury(), platformTreasury);
        assertTrue(factory.bondingCurveImpl() != address(0));
    }

    function testCreateCircle() public {
        vm.startPrank(user1);

        uint256 creationFee = factory.circleCreationFee();

        uint256 circleId = factory.createCircle{value: creationFee}(
            "Test Circle",
            "TEST",
            "A test circle",
            BondingCurve.CurveType.LINEAR,
            0.001 ether,  // base price
            1e15,         // slope
            0,
            0
        );

        assertEq(circleId, 1);
        assertEq(factory.circleCount(), 1);

        // Check circle details
        (
            uint256 id,
            address circleOwner,
            address tokenAddress,
            ,
            string memory name,
            string memory symbol,
            ,
            bool active,

        ) = factory.circles(circleId);

        assertEq(id, 1);
        assertEq(circleOwner, user1);
        assertTrue(active);
        assertEq(name, "Test Circle");
        assertEq(symbol, "TEST");
        assertTrue(tokenAddress != address(0));

        // Check treasury received fee
        assertEq(platformTreasury.balance, creationFee);

        vm.stopPrank();
    }

    function testCreateCircleInsufficientFee() public {
        vm.startPrank(user1);

        vm.expectRevert("Insufficient fee");
        factory.createCircle{value: 0.001 ether}(
            "Test Circle",
            "TEST",
            "A test circle",
            BondingCurve.CurveType.LINEAR,
            0.001 ether,
            1e15,
            0,
            0
        );

        vm.stopPrank();
    }

    function testCreateMultipleCircles() public {
        vm.startPrank(user1);
        uint256 creationFee = factory.circleCreationFee();

        // Create first circle
        uint256 circle1 = factory.createCircle{value: creationFee}(
            "Circle 1",
            "CRC1",
            "First circle",
            BondingCurve.CurveType.LINEAR,
            0.001 ether,
            1e15,
            0,
            0
        );

        // Create second circle
        uint256 circle2 = factory.createCircle{value: creationFee}(
            "Circle 2",
            "CRC2",
            "Second circle",
            BondingCurve.CurveType.EXPONENTIAL,
            0.001 ether,
            0,
            1e16,  // growth rate
            0
        );

        assertEq(circle1, 1);
        assertEq(circle2, 2);
        assertEq(factory.circleCount(), 2);

        // Check user owns both circles
        uint256[] memory userCircles = factory.getOwnerCircles(user1);
        assertEq(userCircles.length, 2);
        assertEq(userCircles[0], 1);
        assertEq(userCircles[1], 2);

        vm.stopPrank();
    }

    function testDeactivateCircle() public {
        vm.startPrank(user1);
        uint256 creationFee = factory.circleCreationFee();

        uint256 circleId = factory.createCircle{value: creationFee}(
            "Test Circle",
            "TEST",
            "A test circle",
            BondingCurve.CurveType.LINEAR,
            0.001 ether,
            1e15,
            0,
            0
        );

        // Deactivate circle
        factory.deactivateCircle(circleId);

        // Check circle is inactive
        (, , , , , , , bool active, ) = factory.circles(circleId);
        assertFalse(active);

        // Reactivate circle
        factory.reactivateCircle(circleId);

        // Check circle is active again
        (, , , , , , , active, ) = factory.circles(circleId);
        assertTrue(active);

        vm.stopPrank();
    }

    function testTransferCircleOwnership() public {
        vm.startPrank(user1);
        uint256 creationFee = factory.circleCreationFee();

        uint256 circleId = factory.createCircle{value: creationFee}(
            "Test Circle",
            "TEST",
            "A test circle",
            BondingCurve.CurveType.LINEAR,
            0.001 ether,
            1e15,
            0,
            0
        );

        // Transfer ownership to user2
        factory.transferCircleOwnership(circleId, user2);

        // Check new owner
        (, address newOwner, , , , , , , ) = factory.circles(circleId);
        assertEq(newOwner, user2);

        // Check user1 no longer owns the circle
        uint256[] memory user1Circles = factory.getOwnerCircles(user1);
        assertEq(user1Circles.length, 0);

        // Check user2 now owns the circle
        uint256[] memory user2Circles = factory.getOwnerCircles(user2);
        assertEq(user2Circles.length, 1);
        assertEq(user2Circles[0], circleId);

        vm.stopPrank();
    }

    function testUpdateCircleCreationFee() public {
        uint256 newFee = 0.05 ether;
        factory.updateCircleCreationFee(newFee);
        assertEq(factory.circleCreationFee(), newFee);
    }

    function testGetStatistics() public {
        vm.startPrank(user1);
        uint256 creationFee = factory.circleCreationFee();

        // Create multiple circles
        for (uint i = 0; i < 3; i++) {
            factory.createCircle{value: creationFee}(
                string(abi.encodePacked("Circle ", vm.toString(i))),
                string(abi.encodePacked("CRC", vm.toString(i))),
                "Test circle",
                BondingCurve.CurveType.LINEAR,
                0.001 ether,
                1e15,
                0,
                0
            );
        }

        vm.stopPrank();

        (uint256 totalCircles, uint256 activeCircles, ) = factory.getStatistics();

        assertEq(totalCircles, 3);
        assertEq(activeCircles, 3);
    }

    function testPauseAndUnpause() public {
        // Pause factory
        factory.pause();

        // Try to create circle (should fail)
        vm.startPrank(user1);
        uint256 creationFee = factory.circleCreationFee();

        vm.expectRevert("Pausable: paused");
        factory.createCircle{value: creationFee}(
            "Test Circle",
            "TEST",
            "A test circle",
            BondingCurve.CurveType.LINEAR,
            0.001 ether,
            1e15,
            0,
            0
        );
        vm.stopPrank();

        // Unpause
        factory.unpause();

        // Now it should work
        vm.startPrank(user1);
        uint256 circleId = factory.createCircle{value: creationFee}(
            "Test Circle",
            "TEST",
            "A test circle",
            BondingCurve.CurveType.LINEAR,
            0.001 ether,
            1e15,
            0,
            0
        );
        assertEq(circleId, 1);
        vm.stopPrank();
    }

    receive() external payable {}
}
