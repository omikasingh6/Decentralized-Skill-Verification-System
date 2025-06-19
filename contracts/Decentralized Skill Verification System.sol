// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Decentralized Skill Verification System
 * @dev A smart contract for verifying and managing professional skills on the blockchain
 * @author Your Name
 */
contract DecentralizedSkillVerificationSystem {
    
    // Struct to represent a skill verification
    struct SkillVerification {
        string skillName;
        string description;
        address verifier;
        uint256 timestamp;
        bool isActive;
        uint8 proficiencyLevel; // 1-5 scale
    }
    
    // Struct to represent a verifier
    struct Verifier {
        string name;
        string expertise;
        bool isActive;
        uint256 verificationCount;
    }
    
    // Mappings
    mapping(address => SkillVerification[]) public userSkills;
    mapping(address => Verifier) public verifiers;
    mapping(address => bool) public isRegisteredVerifier;
    
    // Events
    event SkillVerified(
        address indexed user,
        string skillName,
        address indexed verifier,
        uint8 proficiencyLevel
    );
    
    event VerifierRegistered(
        address indexed verifier,
        string name,
        string expertise
    );
    
    event SkillRevoked(
        address indexed user,
        uint256 skillIndex,
        address indexed verifier
    );
    
    // Modifiers
    modifier onlyRegisteredVerifier() {
        require(isRegisteredVerifier[msg.sender], "Not a registered verifier");
        require(verifiers[msg.sender].isActive, "Verifier is not active");
        _;
    }
    
    modifier validProficiencyLevel(uint8 _level) {
        require(_level >= 1 && _level <= 5, "Proficiency level must be between 1-5");
        _;
    }
    
    /**
     * @dev Register as a skill verifier
     * @param _name Name of the verifier
     * @param _expertise Area of expertise
     */
    function registerVerifier(
        string memory _name,
        string memory _expertise
    ) external {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_expertise).length > 0, "Expertise cannot be empty");
        require(!isRegisteredVerifier[msg.sender], "Already registered as verifier");
        
        verifiers[msg.sender] = Verifier({
            name: _name,
            expertise: _expertise,
            isActive: true,
            verificationCount: 0
        });
        
        isRegisteredVerifier[msg.sender] = true;
        
        emit VerifierRegistered(msg.sender, _name, _expertise);
    }
    
    /**
     * @dev Verify a skill for a user
     * @param _user Address of the user whose skill is being verified
     * @param _skillName Name of the skill
     * @param _description Description of the skill verification
     * @param _proficiencyLevel Proficiency level (1-5)
     */
    function verifySkill(
        address _user,
        string memory _skillName,
        string memory _description,
        uint8 _proficiencyLevel
    ) external onlyRegisteredVerifier validProficiencyLevel(_proficiencyLevel) {
        require(_user != address(0), "Invalid user address");
        require(bytes(_skillName).length > 0, "Skill name cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        
        SkillVerification memory newSkill = SkillVerification({
            skillName: _skillName,
            description: _description,
            verifier: msg.sender,
            timestamp: block.timestamp,
            isActive: true,
            proficiencyLevel: _proficiencyLevel
        });
        
        userSkills[_user].push(newSkill);
        verifiers[msg.sender].verificationCount++;
        
        emit SkillVerified(_user, _skillName, msg.sender, _proficiencyLevel);
    }
    
    /**
     * @dev Get all verified skills for a user
     * @param _user Address of the user
     * @return Array of skill verifications
     */
    function getUserSkills(address _user) external view returns (SkillVerification[] memory) {
        return userSkills[_user];
    }
    
    /**
     * @dev Get active skills count for a user
     * @param _user Address of the user
     * @return Number of active skills
     */
    function getActiveSkillsCount(address _user) external view returns (uint256) {
        uint256 count = 0;
        SkillVerification[] memory skills = userSkills[_user];
        
        for (uint i = 0; i < skills.length; i++) {
            if (skills[i].isActive) {
                count++;
            }
        }
        
        return count;
    }
    
    /**
     * @dev Revoke a skill verification (only by the original verifier)
     * @param _user Address of the user
     * @param _skillIndex Index of the skill in the user's skills array
     */
    function revokeSkill(
        address _user,
        uint256 _skillIndex
    ) external onlyRegisteredVerifier {
        require(_skillIndex < userSkills[_user].length, "Invalid skill index");
        require(userSkills[_user][_skillIndex].verifier == msg.sender, "Only original verifier can revoke");
        require(userSkills[_user][_skillIndex].isActive, "Skill already revoked");
        
        userSkills[_user][_skillIndex].isActive = false;
        
        emit SkillRevoked(_user, _skillIndex, msg.sender);
    }
    
    /**
     * @dev Get verifier information
     * @param _verifier Address of the verifier
     * @return Verifier struct
     */
    function getVerifierInfo(address _verifier) external view returns (Verifier memory) {
        require(isRegisteredVerifier[_verifier], "Not a registered verifier");
        return verifiers[_verifier];
    }
    
    /**
     * @dev Check if an address is a registered and active verifier
     * @param _verifier Address to check
     * @return Boolean indicating if address is an active verifier
     */
    function isActiveVerifier(address _verifier) external view returns (bool) {
        return isRegisteredVerifier[_verifier] && verifiers[_verifier].isActive;
    }
}
